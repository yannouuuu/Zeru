import SwiftUI

@Observable
final class AppSettings {
    var accentColorName: String {
        didSet {
            UserDefaults.standard.set(accentColorName, forKey: "accentColorName")
        }
    }

    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    var appIconName: String {
        didSet {
            UserDefaults.standard.set(appIconName, forKey: "appIconName")
        }
    }

    var notifyPayments: Bool {
        didSet { UserDefaults.standard.set(notifyPayments, forKey: "notif.payments") }
    }
    var notifyRecharges: Bool {
        didSet { UserDefaults.standard.set(notifyRecharges, forKey: "notif.recharges") }
    }
    var notifyTransfers: Bool {
        didSet { UserDefaults.standard.set(notifyTransfers, forKey: "notif.transfers") }
    }
    var notifyLowBalance: Bool {
        didSet { UserDefaults.standard.set(notifyLowBalance, forKey: "notif.lowBalance") }
    }
    var lowBalanceThreshold: Double {
        didSet { UserDefaults.standard.set(lowBalanceThreshold, forKey: "notif.lowBalanceThreshold") }
    }

    init() {
        self.accentColorName = UserDefaults.standard.string(forKey: "accentColorName") ?? "blue"
        let raw = UserDefaults.standard.string(forKey: "appearanceMode") ?? "auto"
        self.appearanceMode = AppearanceMode(rawValue: raw) ?? .auto

        self.appIconName = UserDefaults.standard.string(forKey: "appIconName") ?? AppIconOption.classic.rawValue

        self.notifyPayments = UserDefaults.standard.object(forKey: "notif.payments") as? Bool ?? true
        self.notifyRecharges = UserDefaults.standard.object(forKey: "notif.recharges") as? Bool ?? true
        self.notifyTransfers = UserDefaults.standard.object(forKey: "notif.transfers") as? Bool ?? true
        self.notifyLowBalance = UserDefaults.standard.object(forKey: "notif.lowBalance") as? Bool ?? true
        self.lowBalanceThreshold = UserDefaults.standard.object(forKey: "notif.lowBalanceThreshold") as? Double ?? 2.0
    }

    var accentColor: Color {
        AccentOption.all.first { $0.name == accentColorName }?.color ?? .blue
    }
}

enum AppearanceMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case auto = "auto"

    var label: String {
        switch self {
        case .light: return "Clair"
        case .dark: return "Sombre"
        case .auto: return "Automatique"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .auto: return "circle.lefthalf.filled"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }
}

enum AppIconOption: String, CaseIterable, Identifiable {
    case classic
    case choco
    case cold
    case forest
    case ocean
    case sand
    case summer
    case weird

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: return "Classique"
        case .choco: return "Choco"
        case .cold: return "Cold"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .sand: return "Sand"
        case .summer: return "Summer"
        case .weird: return "Weird"
        }
    }

    var alternateIconName: String? {
        switch self {
        case .classic: return nil
        case .choco: return "AppIconChoco"
        case .cold: return "AppIconCold"
        case .forest: return "AppIconForest"
        case .ocean: return "AppIconOcean"
        case .sand: return "AppIconSand"
        case .summer: return "AppIconSummer"
        case .weird: return "AppIconWeird"
        }
    }

    var assetImageName: String {
        switch self {
        case .classic: return "AppIcon"
        case .choco: return "AppIconChoco"
        case .cold: return "AppIconCold"
        case .forest: return "AppIconForest"
        case .ocean: return "AppIconOcean"
        case .sand: return "AppIconSand"
        case .summer: return "AppIconSummer"
        case .weird: return "AppIconWeird"
        }
    }

    var previewImageName: String {
        switch self {
        case .classic: return "IconPreviewClassic"
        case .choco: return "IconPreviewChoco"
        case .cold: return "IconPreviewCold"
        case .forest: return "IconPreviewForest"
        case .ocean: return "IconPreviewOcean"
        case .sand: return "IconPreviewSand"
        case .summer: return "IconPreviewSummer"
        case .weird: return "IconPreviewWeird"
        }
    }
}

struct AccentOption: Identifiable {
    let id = UUID()
    let name: String
    let color: Color

    static let all: [AccentOption] = [
        AccentOption(name: "blue", color: .blue),
        AccentOption(name: "indigo", color: .indigo),
        AccentOption(name: "purple", color: .purple),
        AccentOption(name: "pink", color: .pink),
        AccentOption(name: "red", color: .red),
        AccentOption(name: "orange", color: .orange),
        AccentOption(name: "yellow", color: .yellow),
        AccentOption(name: "green", color: .green),
        AccentOption(name: "teal", color: .teal),
        AccentOption(name: "mint", color: .mint)
    ]
}

