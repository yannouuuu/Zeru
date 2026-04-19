import UIKit
import SwiftUI

final class AppIconService {
    static let shared = AppIconService()
    private init() {}

    func currentOption() -> AppIconOption {
        guard UIApplication.shared.supportsAlternateIcons else {
            return .classic
        }
        let current = UIApplication.shared.alternateIconName
        return AppIconOption.allCases.first { $0.alternateIconName == current } ?? .classic
    }

    @MainActor
    func setAppIcon(_ option: AppIconOption) async throws {
        guard UIApplication.shared.supportsAlternateIcons else {
            throw AppIconError.notSupported
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(option.alternateIconName) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

enum AppIconError: LocalizedError {
    case notSupported

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "Ce modèle d'appareil ne permet pas de changer l'icône."
        }
    }
}
