//
//  AboutCreatorView.swift
//  Zeru
//
//  À propos : le créateur, le projet, les liens.
//

import SwiftUI

struct AboutCreatorView: View {
    private let linkedInURL  = URL(string: "https://www.linkedin.com/in/yann-renard-91279a283/")!
    private let instagramURL = URL(string: "https://www.instagram.com/yannou.rnd/")!
    private let telegramURL  = URL(string: "https://t.me/yannou.rnd")!
    private let githubURL    = URL(string: "https://github.com/yannouuuu")!
    private let projectURL   = URL(string: "https://github.com/yannouuuu/Zeru")!
    private let issuesURL    = URL(string: "https://github.com/yannouuuu/Zeru/issues")!
    private let avatarURL    = URL(string: "https://github.com/yannouuuu.png")!

    @State private var showAvatarPreview = false

    var body: some View {
        List {
            Section {
                header
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
                    .listRowBackground(Color.clear)
            }

            Section {
                Text("Je développe Zeru en solo, sur mon temps libre, pour simplifier la vie étudiante. Merci de l'utiliser — chaque retour compte vraiment.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section("Le projet") {
                Link(destination: projectURL) {
                    Label("Code source de Zeru", systemImage: "shippingbox")
                }
                Link(destination: issuesURL) {
                    Label("Signaler un problème", systemImage: "exclamationmark.bubble")
                }
            }

            Section("Me joindre") {
                Link(destination: linkedInURL) {
                    Label("LinkedIn", systemImage: "person.crop.square.filled.and.at.rectangle")
                }
                Link(destination: instagramURL) {
                    Label("Instagram", systemImage: "camera")
                }
                Link(destination: telegramURL) {
                    Label("Telegram", systemImage: "paperplane")
                }
                Link(destination: githubURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }

            Section {
                LabeledContent("Version", value: appVersion)
            } footer: {
                Text("Zeru n'est pas affilié à Izly ni aux Crous.")
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAvatarPreview) {
            avatarPreview
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 12) {
            AsyncImage(url: avatarURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    Circle()
                        .fill(.quaternary)
                        .overlay {
                            Text("YR")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(.circle)
            .onTapGesture { showAvatarPreview = true }
            .accessibilityLabel("Photo de Yann Renard")

            VStack(spacing: 3) {
                Text("Yann Renard")
                    .font(.title2.weight(.bold))
                Text("Créateur & développeur de Zeru")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var avatarPreview: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AsyncImage(url: avatarURL) { phase in
                if case .success(let image) = phase {
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(.circle)
                        .padding(40)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationCornerRadius(32)
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
