//
//  OnboardingAmbientBackground.swift
//  Zeru
//
//  Couche de fond globale de l'onboarding (blurs accent + purple + glyphes flottants).
//  Affichée derrière toutes les pages pour permettre un fondu fluide entre Welcome et Features.
//

import SwiftUI

struct OnboardingAmbientBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.22))
                    .frame(width: geo.size.width * 0.9)
                    .blur(radius: 70)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.25)

                Circle()
                    .fill(Color.purple.opacity(0.18))
                    .frame(width: geo.size.width * 0.7)
                    .blur(radius: 80)
                    .offset(x: geo.size.width * 0.32, y: -geo.size.height * 0.05)

                VStack(spacing: 22) {
                    Image(systemName: "creditcard.fill")
                    Image(systemName: "qrcode")
                    Image(systemName: "chart.line.uptrend.xyaxis")
                }
                .font(.system(size: 78, weight: .thin))
                .foregroundStyle(.white.opacity(0.06))
                .rotationEffect(.degrees(-12))
                .offset(y: -geo.size.height * 0.12)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingAmbientBackground()
    }
    .preferredColorScheme(.dark)
}
