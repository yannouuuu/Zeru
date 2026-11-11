//
//  NotificationsSettingsView.swift
//  Zeru
//
//  Alertes : un aperçu de la notification, l'état du système, puis les réglages.
//

import SwiftUI
import UserNotifications

struct NotificationsSettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        @Bindable var settings = settings

        List {
            // Aperçu
            Section {
                notificationPreview
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            // État du système
            Section {
                HStack(spacing: 12) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(statusColor)
                        .frame(width: 28, height: 28)
                        .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.subheadline.weight(.semibold))
                        Text(statusDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if authStatus == .denied || authStatus == .notDetermined {
                        Button("Réglages") {
                            openSystemSettings()
                        }
                        .font(.subheadline.weight(.medium))
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 2)
            }

            // Transactions
            Section("Alertes de transactions") {
                toggle(
                    isOn: $settings.notifyPayments,
                    title: "Paiements",
                    subtitle: "À chaque débit Izly",
                    icon: "fork.knife",
                    tint: .accentColor
                )
                toggle(
                    isOn: $settings.notifyRecharges,
                    title: "Rechargements",
                    subtitle: "Quand ton compte est crédité",
                    icon: "plus",
                    tint: .green
                )
                toggle(
                    isOn: $settings.notifyTransfers,
                    title: "Virements",
                    subtitle: "Entrées et sorties de virements",
                    icon: "arrow.up.arrow.down",
                    tint: .orange
                )
            }
            .disabled(authStatus != .authorized)

            // Solde bas
            Section {
                toggle(
                    isOn: $settings.notifyLowBalance,
                    title: "Rappel de rechargement",
                    subtitle: "Quand le solde passe sous le seuil",
                    icon: "exclamationmark.triangle",
                    tint: .red
                )

                if settings.notifyLowBalance && authStatus == .authorized {
                    Stepper(value: $settings.lowBalanceThreshold, in: 0.5...20.0, step: 0.5) {
                        LabeledContent("Seuil") {
                            Text(settings.lowBalanceThreshold.euroFormatted)
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Solde bas")
            } footer: {
                Text("Les alertes de solde bas ne partent qu'une fois par jour maximum.")
            }
        }
        .navigationTitle("Alertes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            authStatus = await NotificationService.shared.authorizationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Task {
                authStatus = await NotificationService.shared.authorizationStatus()
            }
        }
    }

    // MARK: - Aperçu

    private var notificationPreview: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("IconPreviewClassic")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Zeru")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Text("maintenant")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("Paiement de 3,30 €")
                    .font(.caption.weight(.medium))
                Text("Crous Jussieu — solde restant 21,20 €")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Ligne

    private func toggle(
        isOn: Binding<Bool>,
        title: String,
        subtitle: String,
        icon: String,
        tint: Color
    ) -> some View {
        Toggle(isOn: isOn) {
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
            }
        }
    }

    // MARK: - Statut

    private var statusIcon: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return .green
        case .denied: return .red
        default: return .orange
        }
    }

    private var statusTitle: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "Notifications activées"
        case .denied: return "Notifications bloquées"
        default: return "Notifications non configurées"
        }
    }

    private var statusDescription: String {
        switch authStatus {
        case .authorized, .provisional, .ephemeral: return "Zeru peut t'envoyer des alertes."
        case .denied: return "Autorise les notifications dans Réglages."
        default: return "Autorise les notifications pour recevoir des alertes."
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
