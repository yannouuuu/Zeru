//
//  SettingsView.swift
//  Zeru
//
//  Paramètres : une liste native, des sections claires, des icônes colorées.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(AppSettings.self) private var settings

    @State private var showDonation = false
    @State private var showProfile = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {
                profileSection

                Section("Apparence") {
                    NavigationLink {
                        AppearancePickerView()
                    } label: {
                        settingRow(
                            icon: "circle.lefthalf.filled",
                            tint: .indigo,
                            title: "Thème",
                            value: settings.appearanceMode.label
                        )
                    }

                    NavigationLink {
                        AccentColorPickerView()
                    } label: {
                        LabeledContent {
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1))
                        } label: {
                            Label {
                                Text("Couleur d'accent")
                            } icon: {
                                SettingsIcon(systemName: "paintpalette.fill", tint: .pink)
                            }
                        }
                    }

                    NavigationLink {
                        AppIconPickerView()
                    } label: {
                        settingRow(
                            icon: "app.badge.fill",
                            tint: .blue,
                            title: "Icône de l'app",
                            value: currentIcon.label
                        )
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        settingRow(
                            icon: "bell.badge.fill",
                            tint: .red,
                            title: "Alertes",
                            value: notificationLabel
                        )
                    }

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        settingRow(
                            icon: "hand.raised.fill",
                            tint: .green,
                            title: "Confidentialité & permissions"
                        )
                    }
                }

                Section("À propos") {
                    NavigationLink {
                        AboutCreatorView()
                    } label: {
                        settingRow(
                            icon: "person.text.rectangle.fill",
                            tint: .gray,
                            title: "À propos"
                        )
                    }

                    NavigationLink {
                        ChangelogView()
                    } label: {
                        settingRow(
                            icon: "list.bullet.clipboard.fill",
                            tint: .orange,
                            title: "Nouveautés"
                        )
                    }

                    Button {
                        showDonation = true
                    } label: {
                        settingRow(
                            icon: "heart.fill",
                            tint: .pink,
                            title: "Soutenir Zeru"
                        )
                    }
                    .tint(.primary)
                }

                Section {
                    settingRow(
                        icon: "info.circle.fill",
                        tint: .gray,
                        title: "Version",
                        value: appVersion
                    )

                    Link(destination: URL(string: "mailto:support@zeru.app")!) {
                        settingRow(
                            icon: "envelope.fill",
                            tint: .blue,
                            title: "Contacter le support"
                        )
                    }
                } header: {
                    Text("Application")
                } footer: {
                    Text("Zeru n'est pas affilié à Izly ni aux Crous.")
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                    } label: {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Paramètres")
            .sheet(isPresented: $showDonation) {
                DonationView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheetView(authVM: authVM)
            }
            .task {
                notifStatus = await NotificationService.shared.authorizationStatus()
                settings.appIconName = AppIconService.shared.currentOption().rawValue
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task {
                    notifStatus = await NotificationService.shared.authorizationStatus()
                    settings.appIconName = AppIconService.shared.currentOption().rawValue
                }
            }
        }
    }

    // MARK: - Profil

    private var profileSection: some View {
        Section {
            Button {
                showProfile = true
            } label: {
                HStack(spacing: 14) {
                    avatar

                    VStack(alignment: .leading, spacing: 2) {
                        Text(fullName)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(authVM.profile?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var avatar: some View {
        Group {
            if let image = authVM.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(.circle)
            } else {
                Circle()
                    .fill(.quaternary)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(initials)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    // MARK: - Ligne

    private func settingRow(
        icon: String,
        tint: Color,
        title: String,
        value: String? = nil
    ) -> some View {
        LabeledContent {
            if let value {
                Text(value)
            }
        } label: {
            Label {
                Text(title)
            } icon: {
                SettingsIcon(systemName: icon, tint: tint)
            }
        }
    }

    // MARK: - Valeurs

    private var fullName: String {
        "\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")"
    }

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? ""
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    private var currentIcon: AppIconOption {
        AppIconOption(rawValue: settings.appIconName) ?? .classic
    }

    private var notificationLabel: String {
        switch notifStatus {
        case .authorized, .provisional, .ephemeral: return "Activées"
        case .denied: return "Désactivées"
        default: return "Non configurées"
        }
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}

// MARK: - Icône de réglage

/// La pastille d'icône des réglages : un carré arrondi coloré, symbole blanc.
private struct SettingsIcon: View {
    let systemName: String
    let tint: Color

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(
                tint.gradient,
                in: RoundedRectangle(cornerRadius: 7, style: .continuous)
            )
    }
}

// MARK: - Soutien

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    private let revolut = URL(string: "https://revolut.me/y_renard")!
    private let kofi = URL(string: "https://ko-fi.com/yannrnd")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 14) {
                        Circle()
                            .fill(.quaternary)
                            .frame(width: 88, height: 88)
                            .overlay {
                                Text("☕️")
                                    .font(.system(size: 40))
                            }

                        VStack(spacing: 6) {
                            Text("Offrir un café")
                                .font(.title2.weight(.bold))
                            Text("Zeru est une app gratuite, développée seul pendant mon temps libre. Si tu l'utilises et que tu veux me donner un coup de pouce, c'est par ici.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 12)

                    VStack(spacing: 12) {
                        Link(destination: revolut) {
                            Label("Faire un don via Revolut", systemImage: "heart.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)

                        Link(destination: kofi) {
                            Label("Donner un café sur Ko-fi", systemImage: "cup.and.saucer.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 6) {
                        Text("Merci")
                            .font(.headline)
                        Text("Chaque contribution, même petite, m'aide à continuer à développer Zeru.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Soutenir Zeru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}
