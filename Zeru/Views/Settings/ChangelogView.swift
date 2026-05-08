import SwiftUI

struct ChangelogView: View {

    var body: some View {
        List {
            // Bannière
            Section {
                Image("Bannerv1.0")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
            }

            // Entrées de changelog
            ForEach(ChangelogEntry.all) { entry in
                Section {
                    ForEach(entry.changes, id: \.self) { change in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: change.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(change.color)
                                .frame(width: 18, height: 18)
                                .padding(.top, 1)
                            Text(change.description)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                } header: {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Version \(entry.version)")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                        Spacer()
                        Text(entry.date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }
        }
        .navigationTitle("Changelogs")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Models

struct ChangelogEntry: Identifiable {
    let id = UUID()
    let version: String
    let date: String
    let changes: [ChangelogChange]

    static let all: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.1",
            date: "Avr. 2026",
            changes: [
                .feature("Personnalisation de l'icône de l'app — 8 thèmes disponibles"),
                .feature("Couleur d'accentuation avec carrousel de couleurs"),
                .feature("Page À propos avec halo animé et réseaux sociaux"),
                .improvement("Changelogs intégrés dans l'app"),
                .improvement("Notifications : demande de permission améliorée"),
                .fix("Correction du cache d'icône après redémarrage"),
            ]
        ),
        ChangelogEntry(
            version: "1.0",
            date: "Mars 2026",
            changes: [
                .feature("Lancement de Zeru"),
                .feature("Consultation du solde Izly en temps réel"),
                .feature("Historique des transactions"),
                .feature("Notifications de paiements, rechargements et virements"),
                .feature("Alertes de solde bas configurables"),
                .feature("Thème clair / sombre / automatique"),
            ]
        ),
    ]
}

struct ChangelogChange: Hashable {
    enum Kind: Hashable { case feature, improvement, fix }

    let kind: Kind
    let description: String

    static func feature(_ desc: String)     -> ChangelogChange { .init(kind: .feature,     description: desc) }
    static func improvement(_ desc: String) -> ChangelogChange { .init(kind: .improvement, description: desc) }
    static func fix(_ desc: String)         -> ChangelogChange { .init(kind: .fix,          description: desc) }

    var icon: String {
        switch kind {
        case .feature:     return "sparkles"
        case .improvement: return "arrow.up.circle.fill"
        case .fix:         return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch kind {
        case .feature:     return .accentColor
        case .improvement: return .blue
        case .fix:         return .orange
        }
    }
}
