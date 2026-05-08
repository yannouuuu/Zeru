import SwiftUI

struct AboutCreatorView: View {
    private let linkedInURL  = URL(string: "https://www.linkedin.com/in/yann-renard-91279a283/")!
    private let instagramURL = URL(string: "https://www.instagram.com/yannou.rnd/")!
    private let telegramURL  = URL(string: "https://t.me/yannou.rnd")!
    private let githubURL    = URL(string: "https://github.com/yannouuuu")!
    private let projectURL   = URL(string: "https://github.com/yannouuuu/Zeru")!
    private let mailURL      = URL(string: "https://github.com/yannouuuu/Zeru/issues")!

    private let avatarURL = URL(string: "https://github.com/yannouuuu.png")!

    @State private var appeared:          Bool  = false
    @State private var avatar:            Image?
    @State private var showAvatarPreview: Bool  = false

    var body: some View {
        List {
            Section {
                heroSection
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
            }

            Section("Projet") {
                Link(destination: projectURL) {
                    Label("Code source de Zeru", systemImage: "shippingbox.fill")
                }
                Link(destination: mailURL) {
                    Label("Me contacter", systemImage: "envelope.fill")
                }
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.large)
        .task(id: "avatar") {
            guard avatar == nil else { return }
            guard let (data, _) = try? await URLSession.shared.data(from: avatarURL) else { return }
            guard let uiImg = UIImage(data: data) else { return }
            let img = Image(uiImage: uiImg)
            await MainActor.run { avatar = img }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
        // Preview photo en plein écran
        .sheet(isPresented: $showAvatarPreview) {
            avatarPreviewSheet
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                // Halo isolé dans son propre struct — immunisé contre les re-renders du parent
                SpinningHalo()

                Group {
                    if let avatar {
                        avatar.resizable().scaledToFill()
                    } else {
                        Text("YR")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                }
                .frame(width: 88, height: 88)
                .clipShape(Circle())
                .onLongPressGesture(minimumDuration: 0.4) {
                    showAvatarPreview = true
                }
            }

            VStack(spacing: 6) {
                Text("Yann Renard")
                    .font(.title2.bold())
                Text("Créateur & développeur de Zeru")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                SocialIcon(assetName: "LinkedIn",  fallbackIcon: "person.crop.square.filled.and.at.rectangle", fallbackColor: Color(red: 0.05, green: 0.46, blue: 0.73), url: linkedInURL)
                SocialIcon(assetName: "Instagram", fallbackIcon: "camera.fill",                                fallbackColor: Color(red: 0.93, green: 0.26, blue: 0.46), url: instagramURL)
                SocialIcon(assetName: "Telegram",  fallbackIcon: "paperplane.fill",                            fallbackColor: Color(red: 0.18, green: 0.59, blue: 0.87), url: telegramURL)
                SocialIcon(assetName: "GitHub",    fallbackIcon: "chevron.left.forwardslash.chevron.right",    fallbackColor: Color(.label),                              url: githubURL)
            }

            Text("Je développe Zeru en solo sur mon temps libre pour simplifier la vie étudiante. Merci de l'utiliser — chaque retour compte vraiment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.vertical, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .animation(.spring(response: 0.55, dampingFraction: 0.8), value: appeared)
    }

    // MARK: - Avatar preview sheet

    private var avatarPreviewSheet: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let avatar {
                avatar
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .padding(40)
            } else {
                ProgressView().tint(.white)
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(32)
    }
}

// MARK: - SpinningHalo
// Struct isolé : son animation n'est jamais interrompue par les re-renders du parent

private struct SpinningHalo: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    colors: [.orange, .pink, .purple, .blue, .cyan, .orange],
                    center: .center
                )
            )
            .frame(width: 100, height: 100)
            .blur(radius: 6)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - SocialIcon

private struct SocialIcon: View {
    let assetName: String
    let fallbackIcon: String
    let fallbackColor: Color
    let url: URL

    @State private var pressed = false

    var body: some View {
        Link(destination: url) {
            Group {
                if UIImage(named: assetName) != nil {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: fallbackIcon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(fallbackColor)
                }
            }
            .frame(width: 28, height: 28)
            .padding(12)
            .scaleEffect(pressed ? 0.88 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }
}
