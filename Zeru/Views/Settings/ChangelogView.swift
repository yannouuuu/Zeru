//
//  ChangelogView.swift
//  Zeru
//
//  Nouveautés : une section par version, avec sa date et ses changements.
//

import SwiftUI

struct ChangelogView: View {
    var body: some View {
        List {
            Section {
                Image("Bannerv1.0")
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            ForEach(ChangelogEntry.all) { entry in
                Section {
                    ForEach(entry.changes, id: \.self) { change in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: change.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(change.color)
                                .frame(width: 26, height: 26)
                                .background(
                                    change.color.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                                )

                            Text(change.description)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 3)
                        }
                    }
                } header: {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Version \(entry.version)")
                            .font(.subheadline.weight(.semibold))
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
        .navigationTitle("Nouveautés")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Modèles

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
                .feature("Page À propos avec réseaux sociaux"),
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

    static func feature(_ desc: String) -> ChangelogChange { .init(kind: .feature, description: desc) }
    static func improvement(_ desc: String) -> ChangelogChange { .init(kind: .improvement, description: desc) }
    static func fix(_ desc: String) -> ChangelogChange { .init(kind: .fix, description: desc) }

    var icon: String {
        switch kind {
        case .feature: return "sparkles"
        case .improvement: return "arrow.up.circle.fill"
        case .fix: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch kind {
        case .feature: return .accentColor
        case .improvement: return .blue
        case .fix: return .orange
        }
    }
}
