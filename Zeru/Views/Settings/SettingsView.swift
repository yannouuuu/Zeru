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
                profileSection

                Section("Personnalisation") {
                    NavigationLink {
                        AppearancePickerView()
                    } label: {
                        HStack {
                            Label("Thème", systemImage: settings.appearanceMode.icon)
                            Spacer()
                            Text(settings.appearanceMode.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    NavigationLink {
                        AccentColorPickerView()
                    } label: {
                        HStack {
                            Label("Couleur d'accent", systemImage: "paintpalette.fill")
                            Spacer()
                            Circle()
                                .fill(settings.accentColor)
                                .frame(width: 18, height: 18)
                        }
                    }

                    NavigationLink {
                        AppIconPickerView()
                    } label: {
                        HStack {
                            Label("Icône de l'app", systemImage: "app.badge.fill")
                            Spacer()
                            Text(currentIcon.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationsSettingsView()
                    } label: {
                        HStack {
                            Label("Gérer les alertes", systemImage: "bell.badge.fill")
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

                Section("Soutien & créateur") {
                    NavigationLink {
                        AboutCreatorView()
                    } label: {
                        Label("À propos", systemImage: "person.text.rectangle.fill")
                    }

                    Button {
                        showDonation = true
                    } label: {
                        Label("Soutenir Zeru", systemImage: "heart.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                Section("Application") {
                    NavigationLink {
                        ChangelogView()
                    } label: {
                        Label("Changelogs", systemImage: "list.bullet.clipboard.fill")
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "mailto:support@zeru.app")!) {
                        Label("Contacter le support", systemImage: "envelope.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                    } label: {
                        Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Paramètres")
            .sheet(isPresented: $showDonation) {
                DonationView()
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

    private var profileSection: some View {
        Section {
            HStack(spacing: 14) {
                Group {
                    if let image = authVM.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(.circle)
                    } else {
                        Text(initials)
                            .font(.system(size: 22, weight: .semibold))
                            .frame(width: 60, height: 60)
                            .glassEffect(.regular, in: .circle)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")")
                        .font(.headline)
                    Text(authVM.profile?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label("Compte Izly connecté", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? ""
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    private var currentIcon: AppIconOption {
        AppIconOption(rawValue: settings.appIconName) ?? .classic
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}

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
        case .denied: return "Bloquées"
        default: return "Non configurées"
        }
    }

    private var color: Color {
        switch status {
        case .authorized, .provisional: return .green
        case .denied: return .red
        default: return .secondary
        }
    }
}

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    private let revolut = URL(string: "https://revolut.me/y_renard")!
    private let kofi    = URL(string: "https://ko-fi.com/yannrnd")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
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

                    VStack(spacing: 12) {
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

                        Link(destination: kofi) {
                            HStack(spacing: 10) {
                                Text("☕️")
                                Text("Donner un café sur Ko-fi")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.green)
                    }
                    .padding(.horizontal, 20)

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
