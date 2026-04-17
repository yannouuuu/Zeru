//
//  ContentView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some View {
        Group {
            switch authVM.step {
            case .login:
                LoginView(authVM: authVM)
            case .activation:
                ActivationView(authVM: authVM)
            case .home:
                MainTabView(authVM: authVM)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
            }
            .ignoresSafeArea()
        }
    }
}

