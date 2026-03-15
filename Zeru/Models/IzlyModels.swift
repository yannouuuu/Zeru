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

// MARK: - Transaction
struct IzlyTransaction: Codable, Identifiable {
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

// MARK: - Formatage monétaire (partagé dans tout le module)
extension Double {
    var euroFormatted: String {
        let fmt          = NumberFormatter()
        fmt.numberStyle  = .currency
        fmt.currencyCode = "EUR"
        fmt.locale       = Locale(identifier: "fr_FR")
        return fmt.string(from: NSNumber(value: self)) ?? "\(self) €"
    }
}
