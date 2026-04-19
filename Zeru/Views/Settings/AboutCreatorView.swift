import SwiftUI

struct AboutCreatorView: View {
    private let donationURL = URL(string: "https://revolut.me/y_renard")!
    private let githubProfileURL = URL(string: "https://github.com/yannouuuu")!
    private let projectURL = URL(string: "https://github.com/yannouuuu/Zeru")!
    private let supportMailURL = URL(string: "mailto:support@zeru.app")!

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.9), .pink.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                            .overlay {
                                Text("YR")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Yann Renard")
                                .font(.headline)
                            Text("Créateur de Zeru")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Je développe Zeru en solo sur mon temps libre pour simplifier la vie étudiante. Merci pour ton soutien, tes retours et ton partage de l'app.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Me soutenir") {
                Link(destination: donationURL) {
                    Label("Faire un don (Revolut)", systemImage: "heart.fill")
                        .foregroundStyle(.pink)
                }
            }

            Section("Mes réseaux") {
                Link(destination: githubProfileURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Link(destination: supportMailURL) {
                    Label("Me contacter", systemImage: "envelope.fill")
                }
            }

            Section("Le projet") {
                Link(destination: projectURL) {
                    Label("Code source de Zeru", systemImage: "shippingbox.fill")
                }
            }
        }
        .navigationTitle("À propos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
