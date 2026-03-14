//
//  ContentView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()

    var body: some View {
        switch authVM.step {
        case .login:
            LoginView(authVM: authVM)
        case .activation:
            ActivationView(authVM: authVM)
        case .home:
            MainTabView(authVM: authVM)
        }
    }
}
#Preview {
    ContentView()
}
