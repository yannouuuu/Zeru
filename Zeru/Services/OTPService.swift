//
//  OTPService.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import Foundation
import CryptoKit

enum OTPService {

    static func generate(seed: String, counter: Int) -> String? {
        // La lib TS fait :
        // const packedCounter = packBigEndian(identification.counter)
        // utf8ToBytes(packedCounter) → encode la STRING du counter en UTF-8
        // Donc on encode le counter comme string UTF-8, pas comme entier binaire

        // 1. packBigEndian(counter) → retourne une string représentant
        //    le counter encodé en big-endian puis converti en string
        //    En regardant le code pack.ts, packBigEndian retourne une string
        //    dont les char codes sont les bytes big-endian du counter
        let packed = packBigEndian(counter)

        // 2. Décoder le seed depuis base64
        guard let seedData = Data(base64Encoded: seed) else {
            return nil
        }

        // 3. HMAC-SHA1 avec le packed counter en UTF-8
        let key      = SymmetricKey(data: seedData)
        let message  = Data(packed.utf8)
        let hmac     = HMAC<Insecure.SHA1>.authenticationCode(for: message, using: key)
        let hmacData = Data(hmac)

        // 4. base64url sans padding
        let base64    = hmacData.base64EncodedString()
        let base64url = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        return base64url
    }

    // Reproduit packBigEndian de ~/core/pack.ts
    // Encode un Int en big-endian 8 bytes puis crée une String
    // dont chaque caractère correspond à un byte
    private static func packBigEndian(_ value: Int) -> String {
        var result = ""
        // On prend les 8 bytes en big-endian (octet de poids fort en premier)
        for i in stride(from: 56, through: 0, by: -8) {
            let byte = (value >> i) & 0xFF
            // On crée un caractère dont le code Unicode = la valeur du byte
            if let scalar = Unicode.Scalar(byte) {
                result.append(Character(scalar))
            }
        }
        return result
    }
}
