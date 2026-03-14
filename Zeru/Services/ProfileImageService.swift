//
//  ProfileImageService.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

enum ProfileImageService {

    private static let key = "zeru.profileImage"

    static func save(_ image: UIImage) {
        // On compresse en JPEG pour limiter la taille
        guard let data = image.jpegData(compressionQuality: 0.6) else { return }
        let base64 = data.base64EncodedString()
        UserDefaults.standard.set(base64, forKey: key)
    }

    static func load() -> UIImage? {
        guard let base64 = UserDefaults.standard.string(forKey: key),
              let data   = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }

    static func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
