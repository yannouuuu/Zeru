//
//  AppSettings.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

// "final class" = ne peut pas être hérité, légèrement plus performant
// "@Observable" = nouveau macro iOS 17+ qui remplace ObservableObject
// Plus besoin de @Published sur chaque var !
@Observable
final class AppSettings {

    // ── Couleur d'accent ──────────────────────────────
    // On stocke le nom de la couleur (String) car Color n'est pas Codable
    var accentColorName: String {
        didSet {
            // "didSet" = appelé automatiquement après chaque modification
            UserDefaults.standard.set(accentColorName, forKey: "accentColorName")
        }
    }

    // ── Apparence (clair / sombre / auto) ─────────────
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    // ── Init : on charge depuis UserDefaults ──────────
    init() {
        // ?? = opérateur nil-coalescing : valeur par défaut si nil
        self.accentColorName  = UserDefaults.standard.string(forKey: "accentColorName") ?? "blue"
        let raw               = UserDefaults.standard.string(forKey: "appearanceMode") ?? "auto"
        self.appearanceMode   = AppearanceMode(rawValue: raw) ?? .auto
    }

    // ── Couleur résolue ───────────────────────────────
    var accentColor: Color {
        AccentOption.all.first { $0.name == accentColorName }?.color ?? .blue
    }
}

// ── Les modes d'apparence ──────────────────────────────
// "RawRepresentable" via String = on peut convertir en String et inversement
enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark  = "dark"
    case auto  = "auto"

    var label: String {
        switch self {
        case .light: return "Clair"
        case .dark:  return "Sombre"
        case .auto:  return "Automatique"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark:  return "moon"
        case .auto:  return "circle.lefthalf.filled"
        }
    }

    // Conversion vers le type natif SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark:  return .dark
        case .auto:  return nil  // nil = laisse le système décider
        }
    }
}

// ── Les couleurs disponibles ───────────────────────────
struct AccentOption: Identifiable {
    let id   = UUID()
    let name:  String
    let color: Color

    static let all: [AccentOption] = [
        AccentOption(name: "blue",   color: .blue),
        AccentOption(name: "indigo", color: .indigo),
        AccentOption(name: "purple", color: .purple),
        AccentOption(name: "pink",   color: .pink),
        AccentOption(name: "red",    color: .red),
        AccentOption(name: "orange", color: .orange),
        AccentOption(name: "yellow", color: .yellow),
        AccentOption(name: "green",  color: .green),
        AccentOption(name: "teal",   color: .teal),
        AccentOption(name: "mint",   color: .mint),
    ]
}
