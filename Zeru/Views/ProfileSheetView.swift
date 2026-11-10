//
//  ProfileSheetView.swift
//  Zeru
//
//  Profil : tout sur une page — l'identité, les chiffres, la semaine,
//  les actions. Composants natifs uniquement.
//

import SwiftUI
import PhotosUI
import Charts

struct ProfileSheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isPickerPresented = false
    @State private var didCopy = false

    // MARK: - Données

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
    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? "?"
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }
    private var mealsRemaining: Int {
        max(0, Int(authVM.balance / 3.30))
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
            ScrollView {
                VStack(spacing: 14) {
                    header
                    metricsRow
                    accountBox

                    if hasSpendingThisWeek {
                        weekBox
                    }

                    actions
                    logout
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
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
        HStack(spacing: 14) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let image = authVM.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 76, height: 76)
                                .clipShape(.circle)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 76, height: 76)
                                Text(initials)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .glassEffect(.regular, in: .circle)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.accentColor, in: .circle)
                        .overlay(Circle().strokeBorder(.black.opacity(0.25), lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Changer la photo de profil")

            VStack(alignment: .leading, spacing: 3) {
                Text("\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")")
                    .font(.title3.weight(.bold))
                    .lineLimit(1)

                Text(authVM.profile?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Label("Compte Izly connecté", systemImage: "checkmark.seal.fill")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)

            Gauge(value: Double(min(mealsRemaining, 10)), in: 0...10) {
                Text("repas")
            } currentValueLabel: {
                Text("\(mealsRemaining)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .gaugeStyle(.accessoryCircular)
            .tint(.accentColor)
            .frame(width: 56, height: 56)
            .accessibilityLabel("\(mealsRemaining) repas au RU")
        }
    }

    // MARK: - Les chiffres

    private var metricsRow: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                metric("Solde", authVM.balance.euroFormatted)
                metric("Dépensé", totalSpent.euroFormatted)
                metric("Rechargé", totalTopup.euroFormatted)
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Le compte

    private var accountBox: some View {
        GroupBox("Compte") {
            VStack(spacing: 8) {
                LabeledContent("Identifiant") {
                    Text(authVM.profile?.identifier ?? "")
                        .lineLimit(1)
                }

                Divider()

                LabeledContent("Repas pris") {
                    Text("\(mealCount)").monospacedDigit()
                }

                Divider()

                LabeledContent("Moyenne par repas") {
                    Text(averagePerMeal.euroFormatted).monospacedDigit()
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - La semaine

    private var weekBox: some View {
        GroupBox("Cette semaine") {
            Chart(dailySpending) { day in
                BarMark(
                    x: .value("Jour", day.label),
                    y: .value("Dépensé", day.amount)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(3)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 84)
            .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        HStack(spacing: 10) {
            Button {
                isPickerPresented = true
            } label: {
                Label("Photo", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            ShareLink(item: URL(string: "https://github.com/yannouuuu/Zeru")!) {
                Label("Partager", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                copyIdentifier()
            } label: {
                Label(didCopy ? "Copié" : "Copier", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .font(.subheadline)
        .labelStyle(.titleAndIcon)
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

    // MARK: - Déconnexion

    private var logout: some View {
        Button(role: .destructive) {
            authVM.logout()
            dismiss()
        } label: {
            Text("Se déconnecter")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}

// MARK: - Modèle

private struct DaySpend: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}
