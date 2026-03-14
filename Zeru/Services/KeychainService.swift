//
//  KeychainService.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import Foundation
import Security

enum KeychainService {

    private static let key         = "zeru.identification"
    private static let passwordKey = "zeru.password"
    private static let profileKey  = "zeru.profile"

    // ── Identification ────────────────────────────────

    static func saveIdentification(_ identification: IzlyIdentification) {
        guard let data = try? JSONEncoder().encode(identification) else { return }
        deleteIdentification()
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : key,
            kSecValueData as String          : data,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessible as String     : kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadIdentification() -> IzlyIdentification? {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : key,
            kSecReturnData as String         : true,
            kSecMatchLimit as String         : kSecMatchLimitOne,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let identification = try? JSONDecoder().decode(IzlyIdentification.self, from: data) else {
            return nil
        }
        return identification
    }

    static func deleteIdentification() {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : key,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        SecItemDelete(query as CFDictionary)
    }

    // ── Password ──────────────────────────────────────

    static func savePassword(_ password: String) {
        guard let data = password.data(using: .utf8) else { return }
        deletePassword()
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : passwordKey,
            kSecValueData as String          : data,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessible as String     : kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : passwordKey,
            kSecReturnData as String         : true,
            kSecMatchLimit as String         : kSecMatchLimitOne,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : passwordKey,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        SecItemDelete(query as CFDictionary)
    }

    // ── Profile ───────────────────────────────────────

    static func saveProfile(_ profile: IzlyProfile) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        deleteProfile()
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : profileKey,
            kSecValueData as String          : data,
            kSecAttrSynchronizable as String : kCFBooleanTrue!,
            kSecAttrAccessible as String     : kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func loadProfile() -> IzlyProfile? {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : profileKey,
            kSecReturnData as String         : true,
            kSecMatchLimit as String         : kSecMatchLimitOne,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(IzlyProfile.self, from: data)
    }

    static func deleteProfile() {
        let query: [String: Any] = [
            kSecClass as String              : kSecClassGenericPassword,
            kSecAttrAccount as String        : profileKey,
            kSecAttrSynchronizable as String : kCFBooleanTrue!
        ]
        SecItemDelete(query as CFDictionary)
    }
}
