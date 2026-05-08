import SwiftUI

struct AccentColorPickerView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let current = settings

        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(current.accentColor)
                        Text("Zeru")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(current.accentColor)
                        Button("Aperçu") {}
                            .buttonStyle(.glassProminent)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } header: {
                Text("Aperçu")
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(AccentOption.all) { option in
                            let isSelected = current.accentColorName == option.name
                            Button {
                                current.accentColorName = option.name
                            } label: {
                                ZStack {
                                    // Anneau de sélection visible
                                    Circle()
                                        .strokeBorder(option.color, lineWidth: isSelected ? 3 : 0)
                                        .frame(width: 50, height: 50)

                                    Circle()
                                        .fill(option.color)
                                        .frame(width: isSelected ? 38 : 44, height: isSelected ? 38 : 44)

                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .black))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(width: 56, height: 56)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
            } header: {
                Text("Couleur")
            }
        }
        .navigationTitle("Couleur")
        .navigationBarTitleDisplayMode(.inline)
    }
}
