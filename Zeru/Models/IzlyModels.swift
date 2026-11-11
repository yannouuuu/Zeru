//
//  Models.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import Foundation

// MARK: - Résultat du login
struct LoginResult {
    let salt: String
    let uid:  String
}

// MARK: - Identification (session active)
struct IzlyIdentification: Codable {
    let accessToken:  String
    let refreshToken: String
    var sessionID:    String
    let userID:       String
    var identifier:   String
    var seed:         String
    var counter:      Int
}

// MARK: - Profil utilisateur
struct IzlyProfile: Codable {
    let firstName:  String
    let lastName:   String
    let email:      String
    let identifier: String
}

// MARK: - Résultat du tokenize
struct TokenizeResult {
    let identification: IzlyIdentification
    let profile:        IzlyProfile
    let balance:        Double
}

// MARK: - Tarif CROUS (repas au RU)
/// Le tarif CROUS du compte, exposé par Izly (`GetContactDetails` →
/// `Result.IzlyProfile.NumeroTarif`). Il sert à distinguer les étudiants
/// boursiers des non boursiers.
struct IzlyTariff: Codable, Equatable {
    /// Code tarif CROUS (`NumeroTarif`). `nil` tant que l'information n'est pas connue.
    let number: Int?
    /// Code société CROUS (`CodeSociete`). Information de contexte, pas un critère de tarif.
    let societyCode: Int?

    /// Prix d'un repas au RU.
    /// Depuis le 4 mai 2026, le repas à 1 € est ouvert à tous les étudiants
    /// disposant d'un compte Izly actif : le prix ne dépend plus du statut boursier.
    static let studentMealPrice: Double = 1.00

    /// `true` si le compte est un étudiant boursier.
    /// 98 = boursier national ; 2…89 = tarifs locaux de boursiers régionaux.
    var isBoursier: Bool {
        guard let number else { return false }
        return number == 98 || (2...89).contains(number)
    }

    /// Statut lisible pour l'UI, `nil` tant que le tarif n'est pas connu.
    var statusLabel: String? {
        guard number != nil else { return nil }
        return isBoursier ? "Boursier" : "Non boursier"
    }

    /// Prix d'un repas au RU pour ce compte.
    var mealPrice: Double { Self.studentMealPrice }
}

// MARK: - Transaction
struct IzlyTransaction: Codable, Identifiable, Equatable {
    let id:     String
    let date:   String
    let label:  String
    let amount: Double
    let group:  Int     // 0 = paiements, 1 = rechargements, 2 = virements
    let timestamp: Double
}

// MARK: - Erreurs
enum IzlyError: Error {
    case invalidCredentials
    case networkError(String)
    case parseError
    case unknown
}
