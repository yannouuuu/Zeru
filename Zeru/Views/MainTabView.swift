//
//  MainTabView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var showPaySheet = false

    var body: some View {
        TabView {
            Tab("Accueil", systemImage: "house.fill") {
                HomeView(authVM: authVM)
            }

            Tab("Recharger", systemImage: "plus.circle.fill") {
                RechargeView()
            }

            Tab("Paramètres", systemImage: "gearshape.fill") {
                SettingsView(authVM: authVM)
            }

            // Le rôle .search place un bouton dans la toolbar native
            // On le détourne pour ouvrir le QR code
            Tab("Payer", systemImage: "qrcode", role: .search) {
                PaySheetView(authVM: authVM, isPresented: $showPaySheet)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
