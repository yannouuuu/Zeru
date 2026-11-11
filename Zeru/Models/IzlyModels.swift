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
/// `Result.IzlyProfile.NumeroTarif`). C'est lui qui fixe le prix du repas au RU :
/// 1,00 € pour un étudiant boursier (code 98), 3,30 € pour le tarif étudiant classique.
struct IzlyTariff: Codable, Equatable {
    /// Code tarif CROUS (`NumeroTarif`). `nil` tant que l'information n'est pas connue.
    let number: Int?
    /// Code société CROUS (`CodeSociete`). Information de contexte, pas un critère de tarif.
    let societyCode: Int?

    /// Prix du repas étudiant classique (codes tarif 1 et 97).
    static let standardMealPrice: Double = 3.30
    /// Prix du repas à 1 € (code 98 boursier, code 90 non boursier sous conditions).
    static let reducedMealPrice: Double = 1.00

    /// Codes tarif CROUS qui ouvrent droit au repas à 1 € (98 = boursier,
    /// 90 = non boursier sous conditions spécifiques).
    static let oneEuroTariffs: Set<Int> = [90, 98]

    /// `true` si le compte est un étudiant boursier.
    /// 98 = boursier national ; 2…89 = tarifs locaux de boursiers régionaux.
    var isBoursier: Bool {
        guard let number else { return false }
        return number == 98 || (2...89).contains(number)
    }

    /// Prix d'un repas au RU pour ce compte.
    var mealPrice: Double {
        guard let number else { return Self.standardMealPrice }
        return (isBoursier || Self.oneEuroTariffs.contains(number))
            ? Self.reducedMealPrice
            : Self.standardMealPrice
    }
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
