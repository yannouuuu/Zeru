//
//  NotificationsSettingsView.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var settings = settings

        List {
            // ── Statut système ─────────────────────────
            Section {
                HStack(spacing: 14) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 26))
                        .foregroundStyle(statusColor)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(statusTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if authStatus == .denied || authStatus == .notDetermined {
                        Button("Réglages") {
                            openSystemSettings()
                        }
                        .font(.subheadline)
                        .buttonStyle(.glassProminent)
                    }
                }
                .padding(.vertical, 6)
            }

            // ── Types de notifications ─────────────────
            Section("Alertes de transactions") {
                Toggle(isOn: $settings.notifyPayments) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Paiements")
                            Text("À chaque débit Izly")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "fork.knife.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .disabled(authStatus != .authorized)

                Toggle(isOn: $settings.notifyRecharges) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rechargements")
                            Text("Quand ton compte est crédité")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .disabled(authStatus != .authorized)

                Toggle(isOn: $settings.notifyTransfers) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Virements")
                            Text("Entrées et sorties de virements")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .disabled(authStatus != .authorized)
            }

            // ── Alerte solde bas ───────────────────────
            Section("Alerte solde bas") {
                Toggle(isOn: $settings.notifyLowBalance) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rappel de rechargement")
                            Text("Notification quand le solde est faible")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                .disabled(authStatus != .authorized)

                if settings.notifyLowBalance && authStatus == .authorized {
                    HStack {
                        Label("Seuil d'alerte", systemImage: "eurosign.circle")
                        Spacer()
                        Stepper(
                            value: $settings.lowBalanceThreshold,
                            in: 0.5...20.0,
                            step: 0.5
                        ) {
                            Text(settings.lowBalanceThreshold.euroFormatted)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                }
            }

            // ── Fréquence ──────────────────────────────
            if authStatus == .authorized {
                Section {
                    Label {
                        Text("Les alertes de solde bas ne s'envoient qu'une fois par jour maximum.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task { await refreshStatus() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task { await refreshStatus() }
        }
    }

    // MARK: - Helpers

    private func refreshStatus() async {
        authStatus = await NotificationService.shared.authorizationStatus()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var statusIcon: String {
        switch authStatus {
        case .authorized, .provisional: return "bell.badge.fill"
        case .denied:                   return "bell.slash.fill"
        default:                        return "bell.fill"
        }
    }

    private var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional: return .green
        case .denied:                   return .red
        default:                        return .secondary
        }
    }

    private var statusTitle: String {
        switch authStatus {
        case .authorized, .provisional: return "Notifications autorisées"
        case .denied:                   return "Notifications bloquées"
        default:                        return "Notifications non configurées"
        }
    }

    private var statusDescription: String {
        switch authStatus {
        case .authorized, .provisional:
            return "Zeru peut t'envoyer des alertes."
        case .denied:
            return "Autorise Zeru dans les Réglages iOS."
        default:
            return "Active les notifications pour recevoir des alertes."
        }
    }
}
