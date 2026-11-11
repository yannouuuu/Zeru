//
//  MainTabView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            Tab("Accueil", systemImage: "house.fill") {
                HomeView(authVM: authVM)
            }

            Tab("Recharger", systemImage: "plus.circle.fill") {
                RechargeView()
            }

            Tab("Menu RU", systemImage: "fork.knife") {
                MenuRUView()
            }

            Tab("Paramètres", systemImage: "gearshape.fill") {
                SettingsView(authVM: authVM)
            }

            Tab("Payer", systemImage: "qrcode", role: .search) {
                PaySheetView(authVM: authVM)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
