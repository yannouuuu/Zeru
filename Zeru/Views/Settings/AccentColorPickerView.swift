//
//  AccentColorPickerView.swift
//  Zeru
//
//  Couleur d'accent : un aperçu de ce qu'elle colore, puis la palette.
//

import SwiftUI

struct AccentColorPickerView: View {
    @Environment(AppSettings.self) private var settings

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 5)

    var body: some View {
        List {
            Section {
                preview
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                Text("Aperçu")
            }

            Section {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(AccentOption.all) { option in
                        swatch(option)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Couleur")
            } footer: {
                Text("La couleur d'accent s'applique aux boutons, aux liens et aux sélections.")
            }
        }
        .navigationTitle("Couleur d'accent")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Aperçu

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(settings.accentColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(frenchName(settings.accentColorName))
                        .font(.subheadline.weight(.semibold))
                    Text("Couleur d'accent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Text("Payer au RU")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(settings.accentColor, in: Capsule())

                HStack(spacing: 3) {
                    Text("Recharger")
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(settings.accentColor)

                Spacer()
            }

            HStack(alignment: .bottom, spacing: 5) {
                ForEach([0.35, 0.55, 0.4, 0.75, 0.6, 0.9, 0.7], id: \.self) { value in
                    Capsule()
                        .fill(settings.accentColor.opacity(value))
                        .frame(maxWidth: .infinity)
                        .frame(height: 26 * value + 6)
                }
            }
            .frame(height: 32, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .animation(.snappy, value: settings.accentColorName)
    }

    // MARK: - Noms

    private func frenchName(_ name: String) -> String {
        switch name {
        case "blue": return "Bleu"
        case "indigo": return "Indigo"
        case "purple": return "Violet"
        case "pink": return "Rose"
        case "red": return "Rouge"
        case "orange": return "Orange"
        case "yellow": return "Jaune"
        case "green": return "Vert"
        case "teal": return "Turquoise"
        case "mint": return "Menthe"
        default: return name.capitalized
        }
    }

    // MARK: - Pastille

    private func swatch(_ option: AccentOption) -> some View {
        let isSelected = settings.accentColorName == option.name

        return Button {
            withAnimation(.snappy) {
                settings.accentColorName = option.name
            }
            UISelectionFeedbackGenerator().selectionChanged()
        } label: {
            ZStack {
                Circle()
                    .fill(option.color)
                    .frame(width: 44, height: 44)
                    .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 1, y: 1)
                }
            }
            .overlay {
                Circle()
                    .strokeBorder(option.color, lineWidth: isSelected ? 3 : 0)
                    .padding(-4)
            }
            .scaleEffect(isSelected ? 1.06 : 1)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(frenchName(option.name))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
