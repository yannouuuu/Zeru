//
//  OnboardingView.swift
//  Zeru
//
//  Created by Yann Renard on 18/04/2026.
//

import SwiftUI
import UIOnboarding

struct OnboardingView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIOnboardingViewController

    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIOnboardingViewController {
        let vc = UIOnboardingViewController(withConfiguration: .setUp())
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIOnboardingViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UIOnboardingViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func didFinishOnboarding(onboardingViewController: UIOnboardingViewController) {
            onboardingViewController.modalTransitionStyle = .crossDissolve
            onboardingViewController.dismiss(animated: true) {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                self.onDismiss()
            }
        }
    }
}

// ── Configuration ──────────────────────────────────────

struct UIOnboardingHelper {

    static func setUpIcon() -> UIImage {
        // Utilise ton icône depuis les Assets
        return Bundle.main.appIcon ?? UIImage(systemName: "creditcard.fill")!
    }

    static func setUpFirstTitleLine() -> NSMutableAttributedString {
        .init(string: "Bienvenue sur", attributes: [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ])
    }

    static func setUpSecondTitleLine() -> NSMutableAttributedString {
        .init(string: "Zeru", attributes: [
            .foregroundColor: UIColor(Color.accentColor),
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ])
    }

    static func setUpFeatures() -> [UIOnboardingFeature] {
        [
            .init(
                icon: UIImage(systemName: "creditcard.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))!
                    .withTintColor(.systemBlue, renderingMode: .alwaysOriginal),
                title: "Ton solde en temps réel",
                description: "Consulte ton solde Izly et ton historique de transactions directement depuis l'app."
            ),
            .init(
                icon: UIImage(systemName: "qrcode",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))!
                    .withTintColor(.systemPurple, renderingMode: .alwaysOriginal),
                title: "Payer en un scan",
                description: "Génère ton QR code de paiement en un instant. Valable 30 secondes et renouvelé automatiquement."
            ),
            .init(
                icon: UIImage(systemName: "chart.line.uptrend.xyaxis",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))!
                    .withTintColor(.systemGreen, renderingMode: .alwaysOriginal),
                title: "Suis tes dépenses",
                description: "Visualise l'évolution de ton compte avec un graphe interactif et filtre par type de transaction."
            ),
            .init(
                icon: UIImage(systemName: "lock.shield.fill",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold))!
                    .withTintColor(.systemOrange, renderingMode: .alwaysOriginal),
                title: "Sécurisé & privé",
                description: "Tes identifiants sont chiffrés dans le Keychain iCloud. Zeru ne stocke rien sur ses serveurs."
            )
        ]
    }

    static func setUpNotice() -> UIOnboardingTextViewConfiguration {
        .init(
            icon: UIImage(systemName: "info.circle.fill")!
                .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal),
            text: "Zeru n'est pas affilié à Izly ou Les Crous.",
            linkTitle: "En savoir plus",
            link: "https://github.com/LiterateInk/Ezly.js",
            linkColor: UIColor(Color.accentColor)
        )
    }

    static func setUpButton() -> UIOnboardingButtonConfiguration {
        .init(
            title: "Commencer",
            titleColor: .white,
            backgroundColor: UIColor(Color.accentColor)
        )
    }
}

extension UIOnboardingViewConfiguration {
    static func setUp() -> UIOnboardingViewConfiguration {
        .init(
            appIcon:              UIOnboardingHelper.setUpIcon(),
            firstTitleLine:       UIOnboardingHelper.setUpFirstTitleLine(),
            secondTitleLine:      UIOnboardingHelper.setUpSecondTitleLine(),
            features:             UIOnboardingHelper.setUpFeatures(),
            textViewConfiguration: UIOnboardingHelper.setUpNotice(),
            buttonConfiguration:  UIOnboardingHelper.setUpButton()
        )
    }
}

extension Bundle {
    var appIcon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let files = primary["CFBundleIconFiles"] as? [String],
              let last = files.last else { return nil }
        return UIImage(named: last)
    }
}
