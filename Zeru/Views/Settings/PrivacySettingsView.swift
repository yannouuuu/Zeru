//
//  PrivacySettingsView.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct PrivacySettingsView: View {
    @State private var locationStatus: CLAuthorizationStatus = CLLocationManager().authorizationStatus
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            // ── Permissions système ────────────────────
            Section("Permissions") {
                PermissionRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Localisation",
                    subtitle: "Trouve le RU Crous le plus proche",
                    status: locationStatusLabel,
                    statusColor: locationStatusColor,
                    isDenied: locationStatus == .denied || locationStatus == .restricted,
                    onOpenSettings: openSystemSettings
                )

                PermissionRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notifications",
                    subtitle: "Alertes de paiements et de solde",
                    status: notifStatusLabel,
                    statusColor: notifStatusColor,
                    isDenied: notifStatus == .denied,
                    onOpenSettings: openSystemSettings
                )
            }

            // ── Données stockées ───────────────────────
            Section("Données stockées") {
                DataRow(
                    icon: "lock.fill",
                    iconColor: .green,
                    title: "Identifiants Izly",
                    detail: "Keychain chiffré iOS"
                )
                DataRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: "Profil & photo",
                    detail: "Keychain + UserDefaults local"
                )
                DataRow(
                    icon: "gearshape.fill",
                    iconColor: .gray,
                    title: "Préférences",
                    detail: "UserDefaults local"
                )
                DataRow(
                    icon: "mappin.circle.fill",
                    iconColor: .orange,
                    title: "Restaurant favori",
                    detail: "UserDefaults local"
                )
            }

            // ── Mentions ───────────────────────────────
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Aucune donnée partagée", systemImage: "checkmark.shield.fill")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.green)
                    Text("Toutes tes données restent sur ton appareil. Zeru ne collecte rien et ne communique avec aucun serveur tiers (hors APIs Izly et Crous).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // ── API utilisées ──────────────────────────
            Section("API tierces") {
                Link(destination: URL(string: "https://github.com/LiterateInk/Ezly.js")!) {
                    HStack {
                        Label("API Izly (Ezly.js)", systemImage: "creditcard.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Link(destination: URL(string: "https://github.com/Vexcited/Crowous.js")!) {
                    HStack {
                        Label("API Crous (Crowous.js)", systemImage: "fork.knife")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Confidentialité")
        .navigationBarTitleDisplayMode(.large)
        .task {
            notifStatus = await NotificationService.shared.authorizationStatus()
            locationStatus = CLLocationManager().authorizationStatus
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                notifStatus = await NotificationService.shared.authorizationStatus()
                locationStatus = CLLocationManager().authorizationStatus
            }
        }
    }

    // MARK: - Helpers

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var locationStatusLabel: String {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "Autorisée"
        case .denied, .restricted:                    return "Refusée"
        case .notDetermined:                          return "Non demandée"
        @unknown default:                             return "Inconnu"
        }
    }

    private var locationStatusColor: Color {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted:                    return .red
        default:                                      return .secondary
        }
    }

    private var notifStatusLabel: String {
        switch notifStatus {
        case .authorized, .provisional: return "Autorisées"
        case .denied:                   return "Refusées"
        default:                        return "Non demandées"
        }
    }

    private var notifStatusColor: Color {
        switch notifStatus {
        case .authorized, .provisional: return .green
        case .denied:                   return .red
        default:                        return .secondary
        }
    }
}

// MARK: - Composants

private struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let status: String
    let statusColor: Color
    let isDenied: Bool
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDenied {
                Button("Réglages") { onOpenSettings() }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(statusColor)
            } else {
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct DataRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(iconColor, in: RoundedRectangle(cornerRadius: 7))

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
