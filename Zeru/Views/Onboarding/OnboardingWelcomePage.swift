//
//  OnboardingWelcomePage.swift
//  Zeru
//
//  Page d'accueil de l'onboarding, fidèle au style Remodex (logo + titre + sous-titre + badge bas).
//  L'arrière-plan ambient est désormais géré globalement par OnboardingView pour permettre
//  une transition fluide vers les pages suivantes.
//

import SwiftUI

struct OnboardingWelcomePage: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.45),
                    .init(color: .black.opacity(0.5), location: 0.6),
                    .init(color: .black, location: 0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("IconPreviewClassic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                VStack(spacing: 8) {
                    Text("Zeru")
                        .font(AppFont.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Ton compte Izly, sans prise de tête.")
                        .font(AppFont.subheadline(weight: .regular))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 11, weight: .medium))
                    Text("Identifiants protégés par le Keychain")
                        .font(AppFont.caption(weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingAmbientBackground()
        OnboardingWelcomePage()
    }
    .preferredColorScheme(.dark)
}
