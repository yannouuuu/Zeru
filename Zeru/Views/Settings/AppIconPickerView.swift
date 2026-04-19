import SwiftUI

struct AppIconPickerView: View {
    @Environment(AppSettings.self) private var settings
    @State private var isApplying = false
    @State private var errorMessage: String?

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(AppIconOption.allCases) { option in
                    IconCardView(option: option, isSelected: settings.appIconName == option.rawValue)
                        .onTapGesture {
                            guard !isApplying else { return }
                            Task { await applyIcon(option, settings: settings) }
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Icône de l'app")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if isApplying {
                ProgressView("Mise à jour…")
                    .padding(14)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 20)
                    .transition(.opacity.animation(.easeInOut))
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

    private var errorBinding: Binding<Bool> {
        Binding {
            errorMessage != nil
        } set: { newValue in
            if !newValue { errorMessage = nil }
        }
    }

    @MainActor
    private func applyIcon(_ option: AppIconOption, settings: AppSettings) async {
        isApplying = true
        defer {
            isApplying = false
            // Toujours re-synchroniser avec l'état réel de l'OS après toute tentative
            settings.appIconName = AppIconService.shared.currentOption().rawValue
        }

        do {
            try await AppIconService.shared.setAppIcon(option)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct IconCardView: View {
    let option: AppIconOption
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(option.previewImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )

            Text(option.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}
