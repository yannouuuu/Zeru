//
//  MainTabView.swift
//  Zeru
//
//  Barre d'onglets maison : quatre rubriques dans une capsule de verre,
//  et « Payer » dans sa propre bulle, détachée à droite.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case recharge
    case menu
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Accueil"
        case .recharge: return "Recharger"
        case .menu: return "Menu RU"
        case .settings: return "Paramètres"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .recharge: return "plus.circle.fill"
        case .menu: return "fork.knife"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel

    @State private var selection: AppTab = .home
    @State private var showPay = false

    var body: some View {
        Group {
            switch selection {
            case .home:
                HomeView(authVM: authVM)
            case .recharge:
                RechargeView()
            case .menu:
                MenuRUView()
            case .settings:
                SettingsView(authVM: authVM)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .fullScreenCover(isPresented: $showPay) {
            PaySheetView(authVM: authVM)
        }
    }

    // MARK: - La barre

    private var bottomBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(5)
            .glassEffect(.regular, in: .capsule)

            payBubble
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 2)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab

        return Button {
            guard !isSelected else { return }
            withAnimation(.snappy) { selection = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .medium))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(
                isSelected ? Color.accentColor.opacity(0.16) : Color.clear,
                in: .capsule
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// La bulle « Payer », séparée de la barre comme le bouton recherche d'iOS.
    private var payBubble: some View {
        Button {
            showPay = true
        } label: {
            VStack(spacing: 3) {
                Image(systemName: "qrcode")
                    .font(.system(size: 18, weight: .medium))
                Text("Payer")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.accentColor)
            .frame(width: 64)
            .padding(.vertical, 7)
            .glassEffect(
                .regular.tint(Color.accentColor.opacity(0.18)).interactive(),
                in: .capsule
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Payer")
    }
}
