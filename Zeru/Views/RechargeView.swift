//
//  RechargeView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import SafariServices
import SwiftUI

struct RechargeView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Bientôt disponible", systemImage: "plus.circle")
            } description: {
                Text("Le rechargement depuis Zeru arrive prochainement.\nEn attendant, utilise l'app Izly officielle.")
            } actions: {
                Link(destination: URL(string: "https://mon-espace.izly.fr/Home/Recharge")!) {
                    Text("Recharger sur Izly.fr")
                }
                .buttonStyle(.glassProminent)
            }
            .navigationTitle("Recharger")
        }
    }
}
