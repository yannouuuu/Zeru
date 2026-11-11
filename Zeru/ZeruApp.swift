//
//  ZeruApp.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//


import SwiftUI

@main
struct ZeruApp: App {

    // "@State" dans App = instance unique qui vit toute la durée de l'app
    @State private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                // ".tint()" global = toute l'app hérite de cette couleur
                // Boutons, icônes tab bar, liens, sliders... tout change
                .tint(settings.accentColor)
                // Injecte settings dans l'environment pour que toutes
                // les vues y accèdent avec @Environment(AppSettings.self)
                .environment(settings)
                // Applique le mode d'apparence choisi
                .preferredColorScheme(settings.appearanceMode.colorScheme)
        }
    }
}
