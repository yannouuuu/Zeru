//
//  ActusView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//


import SwiftUI

struct ActusView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Bientôt disponible",
                systemImage: "newspaper",
                description: Text("Les actualités du Crous arrivent bientôt.")
            )
            .navigationTitle("Actus")
        }
    }
}