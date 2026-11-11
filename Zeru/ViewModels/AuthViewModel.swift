//
//  AuthViewModel.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import Combine

@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - États UI
    @Published var step: AuthStep = .login
    @Published var isLoading    = false
    @Published var errorMessage: String?

    // MARK: - Données
    @Published var profile:        IzlyProfile?
    @Published var identification: IzlyIdentification?
    @Published var balance:        Double = 0.0
    @Published var transactions:   [IzlyTransaction] = []
    /// Tarif CROUS du compte (boursier ou non), chargé avec le solde.
    @Published var tariff:         IzlyTariff?

    // MARK: - Tarif / repas

    /// `true` si le compte est un étudiant boursier (repas à 1 €).
    var isBoursier: Bool { tariff?.isBoursier ?? false }

    /// Prix d'un repas au RU pour ce compte (1 € boursier, 3,30 € sinon).
    var mealPrice: Double { tariff?.mealPrice ?? IzlyTariff.standardMealPrice }

    // MARK: - Autres
    @Published var profileImage: UIImage? = nil


    private let service         = IzlyService()
    private var pendingPassword: String? = nil

    private static let tariffCacheKey = "izly.cachedTariff"

    private static func loadCachedTariff() -> IzlyTariff? {
        guard let data = UserDefaults.standard.data(forKey: tariffCacheKey),
              let tariff = try? JSONDecoder().decode(IzlyTariff.self, from: data) else {
            return nil
        }
        return tariff
    }

    private func cacheTariff(_ tariff: IzlyTariff) {
        guard let data = try? JSONEncoder().encode(tariff) else { return }
        UserDefaults.standard.set(data, forKey: Self.tariffCacheKey)
    }

    private static func clearCachedTariff() {
        UserDefaults.standard.removeObject(forKey: tariffCacheKey)
    }
    
    func updateProfileImage(_ image: UIImage) {
        profileImage = image
        ProfileImageService.save(image)
    }

    // MARK: - Init
    init() {
        if DemoMode.isActive {
            profile        = DemoData.profile
            identification = DemoData.identification
            balance        = DemoData.balance
            transactions   = DemoData.transactions
            tariff         = DemoData.tariff
            _step = Published(initialValue: .home)
            return
        }

        if let saved = KeychainService.loadIdentification() {
            identification = saved
            profile = KeychainService.loadProfile()
            profileImage   = ProfileImageService.load()
            tariff         = Self.loadCachedTariff()
            _step = Published(initialValue: .home)
        } else {
            _step = Published(initialValue: .login)
        }
    }

    // MARK: - Démonstration

    /// Entre dans le compte de démonstration (aucun identifiant requis).
    func enterDemoMode() {
        DemoMode.enable()
        profile        = DemoData.profile
        identification = DemoData.identification
        balance        = DemoData.balance
        transactions   = DemoData.transactions
        tariff         = DemoData.tariff
        step           = .home
    }

    // MARK: - Étape 1 : Login
    func login(identifier: String, password: String) async {
        let normalizedIdentifier = identifier.trimmed

        isLoading    = true
        errorMessage = nil
        pendingPassword = password

        do {
            _ = try await service.login(identifier: normalizedIdentifier, password: password)
            step = .activation
        } catch IzlyError.networkError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Étape 2 : Tokenize
    func tokenize(activationURL: String) async {
        let normalizedActivationURL = activationURL.trimmed

        isLoading    = true
        errorMessage = nil

        do {
            let finalURL: String
            if normalizedActivationURL.hasPrefix("https://") {
                finalURL = try await service.extractActivationURL(from: normalizedActivationURL)
            } else {
                finalURL = normalizedActivationURL
            }

            let result     = try await service.tokenize(activationURL: finalURL)
            identification = result.identification
            profile        = result.profile
            balance        = result.balance
            step           = .home

            KeychainService.saveIdentification(result.identification)
            KeychainService.saveProfile(result.profile)

            if let pwd = pendingPassword {
                KeychainService.savePassword(pwd)
                pendingPassword = nil
            }

            // Demande la permission de notifier au bon moment (juste après le premier login)
            await NotificationService.shared.requestAuthorizationIfNeeded()

        } catch IzlyError.networkError(let msg) {
            errorMessage = msg
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Charger solde + transactions
    func loadTransactions() async {
        if DemoMode.isActive { return }

        guard var identification = identification else { return }

        do {
            try await fetchAll(identification: identification)
        } catch IzlyError.parseError {
            guard let password = KeychainService.loadPassword() else {
                KeychainService.deleteIdentification()
                step = .login
                return
            }
            do {
                try await service.refresh(identification: &identification, password: password)
                self.identification = identification
                KeychainService.saveIdentification(identification)
                try await fetchAll(identification: identification)
            } catch IzlyError.invalidCredentials {
                KeychainService.deleteIdentification()
                KeychainService.deletePassword()
                step = .login
            } catch {}
        } catch {}
    }

    private func fetchAll(identification: IzlyIdentification) async throws {
        let isInitialLoad = transactions.isEmpty

        async let balanceFetch   = service.fetchBalance(identification: identification)
        async let paymentsFetch  = service.fetchOperations(identification: identification, group: 0)
        async let topupFetch     = service.fetchOperations(identification: identification, group: 1)
        async let transfersFetch = service.fetchOperations(identification: identification, group: 2)
        async let tariffFetch    = service.fetchTariff(identification: identification)

        let (newBalance, payments, topup, transfers) = try await (
            balanceFetch,
            paymentsFetch,
            topupFetch,
            transfersFetch
        )

        balance      = newBalance
        transactions = (payments + topup + transfers).sorted { $0.timestamp > $1.timestamp }

        // Notifications : on passe isInitialLoad=true lors du premier chargement
        // pour enregistrer les IDs sans spammer l'utilisateur avec des anciennes transactions.
        await NotificationService.shared.processNewTransactions(
            transactions,
            balance: newBalance,
            isInitialLoad: isInitialLoad
        )

        // Le tarif CROUS n'est pas bloquant : si l'appel échoue, on garde le tarif connu.
        if let newTariff = try? await tariffFetch {
            tariff = newTariff
            cacheTariff(newTariff)
        }
    }

    // MARK: - Déconnexion
    func logout() {
        Self.clearCachedTariff()

        if DemoMode.isActive {
            DemoMode.disable()
            identification = nil
            profile        = nil
            balance        = 0.0
            transactions   = []
            tariff         = nil
            step           = .login
            return
        }

        KeychainService.deleteIdentification()
        KeychainService.deletePassword()
        KeychainService.deleteProfile()
        ProfileImageService.delete()
        
        identification = nil
        profile        = nil
        balance        = 0.0
        transactions   = []
        tariff         = nil
        step           = .login
    }
}

// MARK: - Étapes du flow
enum AuthStep {
    case login
    case activation
    case home
}
