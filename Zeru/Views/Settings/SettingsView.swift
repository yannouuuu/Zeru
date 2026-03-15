//
//  SettingsView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(AppSettings.self) private var settings
    @State private var showDonation = false
    @State private var notifStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            List {

                // ── Profil ─────────────────────────────────
                Section {
                    HStack(spacing: 14) {
                        Group {
                            if let image = authVM.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipShape(.circle)
                            } else {
                                Text(initials)
                                    .font(.system(size: 22, weight: .semibold))
                                    .frame(width: 56, height: 56)
                                    .glassEffect(.regular, in: .circle)
                            }
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")")
                                .font(.headline)
                            Text(authVM.profile?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                // ── Apparence ──────────────────────────────
                Section("Apparence") {
                    NavigationLink {
                        AccentColorPickerView()
                    } label: {
                        HStack {
                            Label("Couleur", systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: 20, height: 20)
                        }
                    }

                    NavigationLink {
                        AppearancePickerView()
                    } label: {
                        Label("Thème", systemImage: settings.appearanceMode.icon)
                    }
                }

                // ── Compte ─────────────────────────────────
                Section("Compte") {
                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        HStack {
                            Label("Notifications", systemImage: "bell.badge")
                            Spacer()
                            NotificationStatusBadge(status: notifStatus)
                        }
                    }

                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        Label("Confidentialité & permissions", systemImage: "hand.raised.fill")
                    }
                }

                // ── Donation ───────────────────────────────────────────
                Section {
                    Button {
                        showDonation = true
                    } label: {
                        HStack(spacing: 12) {
                            Text("☕️")
                                .font(.title2)
                            Text("Soutenir Zeru")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Étudiant & solo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .tint(.orange)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.25))
                    )
                }

                // ── Application ────────────────────────────
                Section("Application") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://github.com/LiterateInk/Ezly.js")!) {
                        Label("Propulsé par Ezly.js", systemImage: "chevron.left.forwardslash.chevron.right")
                    }

                    Link(destination: URL(string: "mailto:support@zeru.app")!) {
                        Label("Contacter le support", systemImage: "envelope")
                    }
                }

                // ── Déconnexion ────────────────────────────
                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                    } label: {
                        Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Paramètres")
            .sheet(isPresented: $showDonation) {
                DonationView()
            }
            .task { notifStatus = await NotificationService.shared.authorizationStatus() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                Task { notifStatus = await NotificationService.shared.authorizationStatus() }
            }
        }
    }

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? ""
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }
}

// MARK: - Badge statut notifications

struct NotificationStatusBadge: View {
    let status: UNAuthorizationStatus

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch status {
        case .authorized, .provisional: return "Actives"
        case .denied:                   return "Bloquées"
        default:                        return "Non configurées"
        }
    }

    private var color: Color {
        switch status {
        case .authorized, .provisional: return .green
        case .denied:                   return .red
        default:                        return .secondary
        }
    }
}

// ── Vue donation ───────────────────────────────────────
struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    private let revolut = URL(string: "https://revolut.me/y_renard")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // ── Header ─────────────────────────────
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.pink.opacity(0.2), .orange.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            Text("☕️")
                                .font(.system(size: 48))
                        }

                        VStack(spacing: 8) {
                            Text("Offrir un café")
                                .font(.title2.bold())
                            Text("Zeru est une app gratuite développée seul pendant mon temps libre. Si tu l'utilises et que tu veux me donner un coup de pouce, c'est par ici 🙏")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)

                    // ── Bouton Revolut ─────────────────────
                    Link(destination: revolut) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                            Text("Faire un don via Revolut")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.glassProminent)
                    .padding(.horizontal, 20)

                    // ── Message perso ──────────────────────
                    VStack(spacing: 8) {
                        Text("Merci 🫶")
                            .font(.headline)
                        Text("Chaque contribution, même petite, m'aide à continuer à développer Zeru et à l'améliorer.")
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
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .frame(width: 30, height: 30)
                            .glassEffect(.regular, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// ── Pill ───────────────────────────────────────────────
struct FeaturePill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}
