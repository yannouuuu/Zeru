//
//  ProfileSheetView.swift
//  Zeru
//
//  Profil : l'en-tête (avatar, nom, état), une rangée d'actions,
//  puis les informations du compte en liste native.
//

import SwiftUI
import PhotosUI
import Charts

struct ProfileSheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var isPickerPresented = false
    @State private var didCopy = false

    // MARK: - Données

    private var fullName: String {
        "\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")"
    }

    private var initials: String {
        let first = authVM.profile?.firstName.prefix(1) ?? "?"
        let last = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    private var totalSpent: Double {
        authVM.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }

    private var totalTopup: Double {
        authVM.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }

    private var mealCount: Int {
        authVM.transactions.filter { $0.amount < 0 }.count
    }

    private var averagePerMeal: Double {
        guard mealCount > 0 else { return 0 }
        return totalSpent / Double(mealCount)
    }

    private var dailySpending: [DaySpend] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEEE"

        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }

        return days.map { day in
            let total = authVM.transactions
                .filter { $0.amount < 0 }
                .filter {
                    calendar.isDate(
                        Date(timeIntervalSince1970: $0.timestamp / 1000),
                        inSameDayAs: day
                    )
                }
                .reduce(0) { $0 + abs($1.amount) }
            return DaySpend(label: formatter.string(from: day), amount: total)
        }
    }

    private var hasSpendingThisWeek: Bool {
        dailySpending.contains { $0.amount > 0 }
    }

    // MARK: - Corps

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section {
                    actionRow
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 12, trailing: 8))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                Section("Compte") {
                    LabeledContent("Solde") {
                        Text(authVM.balance.euroFormatted)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }

                    LabeledContent("Identifiant") {
                        Text(authVM.profile?.identifier ?? "")
                            .lineLimit(1)
                    }
                }

                Section("Statistiques") {
                    LabeledContent("Dépensé") {
                        Text(totalSpent.euroFormatted).monospacedDigit()
                    }
                    LabeledContent("Rechargé") {
                        Text(totalTopup.euroFormatted).monospacedDigit()
                    }
                    LabeledContent("Repas pris") {
                        Text("\(mealCount)").monospacedDigit()
                    }
                    LabeledContent("Moyenne par repas") {
                        Text(averagePerMeal.euroFormatted).monospacedDigit()
                    }
                }

                if hasSpendingThisWeek {
                    Section("Cette semaine") {
                        Chart(dailySpending) { day in
                            BarMark(
                                x: .value("Jour", day.label),
                                y: .value("Dépensé", day.amount)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .cornerRadius(4)
                        }
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 110)
                        .padding(.vertical, 6)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                        dismiss()
                    } label: {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .photosPicker(isPresented: $isPickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    authVM.updateProfileImage(image)
                }
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.accentColor.opacity(0.45),
                                Color.accentColor.opacity(0.12),
                                .clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: 118
                        )
                    )
                    .frame(width: 236, height: 236)
                    .blur(radius: 6)
                    .allowsHitTesting(false)

                avatar
            }
            .frame(height: 128)

            VStack(spacing: 3) {
                Text(fullName)
                    .font(.title2.weight(.bold))

                Text(authVM.profile?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Label("Compte Izly connecté", systemImage: "checkmark.seal.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 2)
    }

    private var avatar: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = authVM.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Text(initials)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .frame(width: 108, height: 108)
                .clipShape(.circle)
                .overlay {
                    Circle().strokeBorder(.white.opacity(0.14), lineWidth: 1)
                }

                Image(systemName: "camera.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor, in: .circle)
                    .overlay(Circle().strokeBorder(.black.opacity(0.30), lineWidth: 2))
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Changer la photo de profil")
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(alignment: .top, spacing: 0) {
            Button {
                isPickerPresented = true
            } label: {
                actionLabel(icon: "camera.fill", title: "Photo", tint: .blue)
            }
            .buttonStyle(.plain)

            ShareLink(item: URL(string: "https://github.com/yannouuuu/Zeru")!) {
                actionLabel(icon: "square.and.arrow.up", title: "Partager", tint: .indigo)
            }
            .buttonStyle(.plain)

            Button {
                copyIdentifier()
            } label: {
                actionLabel(
                    icon: didCopy ? "checkmark" : "doc.on.doc",
                    title: didCopy ? "Copié" : "Copier",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private func actionLabel(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(tint.gradient, in: .circle)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func copyIdentifier() {
        UIPasteboard.general.string = authVM.profile?.identifier ?? authVM.profile?.email
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        withAnimation(.snappy) { didCopy = true }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.snappy) { didCopy = false }
        }
    }
}

// MARK: - Modèle

private struct DaySpend: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}
