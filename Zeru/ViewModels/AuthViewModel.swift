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
    
    // MARK: - Autres
    @Published var profileImage: UIImage? = nil


    private let service         = IzlyService()
    private var pendingPassword: String? = nil
    
    func updateProfileImage(_ image: UIImage) {
        profileImage = image
        ProfileImageService.save(image)
    }

    // MARK: - Init
    init() {
        if let saved = KeychainService.loadIdentification() {
            identification = saved
            profile = KeychainService.loadProfile()
            profileImage   = ProfileImageService.load()
            _step = Published(initialValue: .home)
        } else {
            _step = Published(initialValue: .login)
        }
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
    }

    // MARK: - Déconnexion
    func logout() {
        KeychainService.deleteIdentification()
        KeychainService.deletePassword()
        KeychainService.deleteProfile()
        ProfileImageService.delete()
        
        identification = nil
        profile        = nil
        balance        = 0.0
        transactions   = []
        step           = .login
    }
}

// MARK: - Étapes du flow
enum AuthStep {
    case login
    case activation
    case home
}
