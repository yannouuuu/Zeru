//
//  PrivacySettingsView.swift
//  Zeru
//
//  Confidentialité : ce qui est demandé, ce qui est stocké, ce qui sort.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct PrivacySettingsView: View {
    @State private var locationStatus: CLAuthorizationStatus = CLLocationManager().authorizationStatus
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Tout reste sur cet iPhone", systemImage: "lock.shield.fill")
                        .font(.headline)
                        .foregroundStyle(.green)

                    Text("Zeru n'a aucun serveur. Tes données ne servent qu'à afficher ton compte, et rien n'est partagé avec un tiers en dehors des API Izly et Crous.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section("Permissions") {
                permissionRow(
                    icon: "location.fill",
                    tint: .blue,
                    title: "Localisation",
                    subtitle: "Trouve le RU Crous le plus proche",
                    status: locationStatusLabel,
                    statusColor: locationStatusColor,
                    isDenied: locationStatus == .denied || locationStatus == .restricted
                )

                permissionRow(
                    icon: "bell.fill",
                    tint: .red,
                    title: "Notifications",
                    subtitle: "Alertes de paiements et de solde",
                    status: notifStatusLabel,
                    statusColor: notifStatusColor,
                    isDenied: notifStatus == .denied
                )
            }

            Section("Données stockées") {
                LabeledContent("Identifiants Izly") {
                    Text("Keychain chiffré")
                }
                LabeledContent("Profil & photo") {
                    Text("Keychain + local")
                }
                LabeledContent("Préférences") {
                    Text("Sur l'appareil")
                }
                LabeledContent("Restaurant favori") {
                    Text("Sur l'appareil")
                }
            }

            Section("API tierces") {
                Link(destination: URL(string: "https://github.com/LiterateInk/Ezly.js")!) {
                    LabeledContent("API Izly (Ezly.js)") {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://github.com/Vexcited/Crowous.js")!) {
                    LabeledContent("API Crous (Crowous.js)") {
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Confidentialité")
        .navigationBarTitleDisplayMode(.inline)
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

    // MARK: - Ligne de permission

    private func permissionRow(
        icon: String,
        tint: Color,
        title: String,
        subtitle: String,
        status: String,
        statusColor: Color,
        isDenied: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isDenied {
                Button("Réglages") {
                    openSystemSettings()
                }
                .font(.caption.weight(.medium))
                .buttonStyle(.bordered)
            } else {
                Text(status)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Helpers

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var locationStatusLabel: String {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return "Autorisée"
        case .denied, .restricted: return "Refusée"
        case .notDetermined: return "Non demandée"
        @unknown default: return "Inconnu"
        }
    }

    private var locationStatusColor: Color {
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways: return .green
        case .denied, .restricted: return .red
        default: return .secondary
        }
    }

    private var notifStatusLabel: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral: return "Autorisées"
        case .denied: return "Refusées"
        default: return "Non demandées"
        }
    }

    private var notifStatusColor: Color {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
}
