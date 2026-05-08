//
//  OnboardingView.swift
//  Zeru
//
//  Onboarding paginé style Remodex (TabView + bottom bar fixe + dots animés).
//

import SwiftUI

struct OnboardingView: View {
    var onDismiss: () -> Void

    @State private var currentPage = 0

    private let pageCount = 4

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            OnboardingAmbientBackground()
                .opacity(ambientOpacity)
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)

                    OnboardingFeaturesPage()
                        .tag(1)

                    OnboardingStepPage(
                        stepNumber: 1,
                        icon: "person.crop.circle.badge.checkmark",
                        title: "Connecte ton compte Izly",
                        description: "Utilise ton email ou ton numéro Izly avec ton mot de passe habituel. Zeru s'occupe ensuite de récupérer ton solde et tes opérations."
                    )
                    .tag(2)

                    OnboardingStepPage(
                        stepNumber: 2,
                        icon: "lock.shield.fill",
                        title: "Tes données restent à toi",
                        description: "Tes identifiants sont chiffrés dans le Keychain iCloud. Zeru n'a aucun serveur et ne stocke rien.",
                        caption: "Zeru n'est pas affilié à Izly ou aux Crous."
                    )
                    .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.18))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)

            PrimaryCapsuleButton(title: buttonTitle, action: handleContinue)

            OpenSourceBadge(style: .light)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.6), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 50)
            .offset(y: -50),
            alignment: .top
        )
    }

    // MARK: - State

    private var ambientOpacity: Double {
        switch currentPage {
        case 0: 1.0
        case 1: 0.35
        default: 0.0
        }
    }

    private var buttonTitle: String {
        switch currentPage {
        case 0: return "Découvrir"
        case 1: return "Continuer"
        case pageCount - 1: return "Se connecter"
        default: return "Continuer"
        }
    }

    private func handleContinue() {
        if currentPage < pageCount - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        } else {
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            onDismiss()
        }
    }
}

// MARK: - Previews

#Preview("Full Flow") {
    OnboardingView { print("Dismiss") }
}
