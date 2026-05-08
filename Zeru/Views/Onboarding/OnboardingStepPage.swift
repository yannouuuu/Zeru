//
//  OnboardingStepPage.swift
//  Zeru
//
//  Page d'étape style Remodex (icon glass dans un cadre + label STEP + titre + description + caption optionnelle).
//

import SwiftUI

struct OnboardingStepPage: View {
    let stepNumber: Int
    let icon: String
    let title: String
    let description: String
    var caption: String? = nil

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color.accentColor.opacity(0.06), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 340
            )
            .offset(y: -60)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 36) {
                    iconView

                    VStack(spacing: 12) {
                        Text("ÉTAPE \(stepNumber)")
                            .font(AppFont.caption2(weight: .bold))
                            .foregroundStyle(Color.accentColor.opacity(0.7))
                            .kerning(1.5)

                        Text(title)
                            .font(AppFont.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text(description)
                            .font(AppFont.subheadline(weight: .regular))
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if let caption {
                        Text(caption)
                            .font(AppFont.caption())
                            .foregroundStyle(.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.accentColor.opacity(0.18), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(accentGradient, lineWidth: 1)
                )
        }
    }
}

#Preview("Step Connexion") {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingStepPage(
            stepNumber: 1,
            icon: "person.crop.circle.badge.checkmark",
            title: "Connecte ton compte Izly",
            description: "Utilise ton email ou ton numéro Izly avec ton mot de passe habituel."
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Step Sécurité") {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingStepPage(
            stepNumber: 2,
            icon: "lock.shield.fill",
            title: "Tes données restent à toi",
            description: "Tes identifiants sont chiffrés dans le Keychain iCloud.",
            caption: "Zeru n'est pas affilié à Izly ou aux Crous."
        )
    }
    .preferredColorScheme(.dark)
}
