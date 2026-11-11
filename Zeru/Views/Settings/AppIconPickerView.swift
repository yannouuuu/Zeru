//
//  AppIconPickerView.swift
//  Zeru
//
//  Icône de l'app : une grille de tirages, une sélection, rien d'autre.
//

import SwiftUI

struct AppIconPickerView: View {
    @Environment(AppSettings.self) private var settings

    @State private var isApplying = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 22) {
                ForEach(AppIconOption.allCases) { option in
                    iconCell(option)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Icône de l'app")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isApplying {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView()
                }
            }
        }
        .alert("Impossible de changer l'icône", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Une erreur inconnue est survenue.")
        }
        .task {
            let currentSystemIcon = AppIconService.shared.currentOption().rawValue
            if settings.appIconName != currentSystemIcon {
                settings.appIconName = currentSystemIcon
            }
        }
    }

    // MARK: - Cellule

    private func iconCell(_ option: AppIconOption) -> some View {
        let isSelected = settings.appIconName == option.rawValue

        return Button {
            guard !isApplying else { return }
            Task { await applyIcon(option) }
        } label: {
            VStack(spacing: 8) {
                Image(option.previewImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 76)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 3)
                    }

                Text(option.label)
                    .font(.caption)
                    .foregroundStyle(.primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    // MARK: - Application

    private var errorBinding: Binding<Bool> {
        Binding {
            errorMessage != nil
        } set: { newValue in
            if !newValue { errorMessage = nil }
        }
    }

    @MainActor
    private func applyIcon(_ option: AppIconOption) async {
        isApplying = true
        defer {
            isApplying = false
            settings.appIconName = AppIconService.shared.currentOption().rawValue
        }

        do {
            try await AppIconService.shared.setAppIcon(option)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
