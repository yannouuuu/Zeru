//
//  AppearancePickerView.swift
//  Zeru
//
//  Apparence : un aperçu vivant de la carte du solde, puis les trois modes.
//

import SwiftUI

struct AppearancePickerView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        List {
            Section {
                preview
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                    Button {
                        withAnimation(.snappy) {
                            settings.appearanceMode = mode
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tint)
                                .frame(width: 28, height: 28)
                                .background(.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                            Text(mode.label)
                                .foregroundStyle(.primary)

                            Spacer()

                            if settings.appearanceMode == mode {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.tint)
                                    .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Automatique suit le réglage d'apparence de ton iPhone.")
            }
        }
        .navigationTitle("Apparence")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Aperçu

    @ViewBuilder
    private var preview: some View {
        if settings.appearanceMode == .auto {
            HStack(spacing: 12) {
                miniPreview(scheme: .light, caption: "Clair")
                miniPreview(scheme: .dark, caption: "Sombre")
            }
        } else {
            miniPreview(
                scheme: settings.appearanceMode.colorScheme ?? .light,
                caption: nil
            )
            .frame(maxWidth: 220)
        }
    }

    private func miniPreview(scheme: ColorScheme, caption: String?) -> some View {
        VStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Solde disponible")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("24,50 €")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Capsule().fill(.tint).frame(width: 42, height: 4)
                    Capsule().fill(.quaternary).frame(width: 22, height: 4)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )

            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(
            Color(uiColor: .systemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .environment(\.colorScheme, scheme)
    }
}
