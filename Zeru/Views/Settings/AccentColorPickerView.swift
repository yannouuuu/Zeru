//
//  AccentColorPickerView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct AccentColorPickerView: View {
    @Environment(AppSettings.self) private var settings

    // "@Bindable" = permet de créer des bindings depuis un @Observable
    // Nécessaire car @Environment ne donne pas de binding direct
    @Bindable private var bindableSettings: AppSettings

    // Init pour initialiser bindableSettings depuis settings
    init() {
        // On crée un placeholder — sera remplacé par environment dans body
        self._bindableSettings = Bindable(AppSettings())
    }

    var body: some View {
        // On utilise settings directement de l'environment
        let current = settings

        return List {
            Section {
                // Prévisualisation en temps réel
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(current.accentColor)
                        Text("Zeru")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(current.accentColor)
                        Button("Aperçu") {}
                            .buttonStyle(.glassProminent)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } header: {
                Text("Aperçu")
            }

            Section("Couleur") {
                ForEach(AccentOption.all) { option in
                    Button {
                        // Modification directe — didSet dans AppSettings
                        // sauvegarde automatiquement dans UserDefaults
                        current.accentColorName = option.name
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(option.color)
                                .frame(width: 28, height: 28)

                            Text(option.name.capitalized)
                                .foregroundStyle(.primary)

                            Spacer()

                            // Coche si sélectionné
                            if current.accentColorName == option.name {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(option.color)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Couleur")
        .navigationBarTitleDisplayMode(.inline)
    }
}
