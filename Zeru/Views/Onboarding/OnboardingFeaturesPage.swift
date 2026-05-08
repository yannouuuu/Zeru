//
//  OnboardingFeaturesPage.swift
//  Zeru
//
//  Page de bénéfices alignée sur OnboardingFeaturesPage de Remodex.
//

import SwiftUI

struct OnboardingFeaturesPage: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 40) {
                VStack(spacing: 10) {
                    Text("Ce que Zeru t'apporte")
                        .font(AppFont.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Tout ce qu'il faut pour utiliser\nIzly plus vite au quotidien.")
                        .font(AppFont.subheadline())
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                VStack(spacing: 16) {
                    OnboardingFeatureRow(
                        icon: "creditcard.fill",
                        color: .blue,
                        title: "Solde en temps réel",
                        subtitle: "Consulte ton solde Izly et ton historique"
                    )

                    OnboardingFeatureRow(
                        icon: "qrcode",
                        color: .purple,
                        title: "Paiement par QR code",
                        subtitle: "Génère ton QR de paiement en un instant"
                    )

                    OnboardingFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green,
                        title: "Suivi des dépenses",
                        subtitle: "Visualise tes opérations avec un graphe interactif"
                    )

                    OnboardingFeatureRow(
                        icon: "lock.shield.fill",
                        color: .orange,
                        title: "Sécurité d'abord",
                        subtitle: "Tes identifiants restent dans le Keychain iCloud"
                    )
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }
}

struct OnboardingFeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.subheadline(weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(subtitle)
                    .font(AppFont.caption())
                    .foregroundStyle(.white.opacity(0.4))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingFeaturesPage()
    }
    .preferredColorScheme(.dark)
}
