//
//  ProfileSheetView.swift
//  Zeru
//
//  Profil : une carte de membre, un bilan, une semaine de dépenses.
//

import SwiftUI
import PhotosUI
import Charts

struct ProfileSheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var isPickerPresented = false

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
            ScrollView {
                VStack(spacing: 24) {
                    memberCard
                    statsSection

                    if hasSpendingThisWeek {
                        spendingSection
                    }

                    actionsSection
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
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

    // MARK: - La carte

    private var memberCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                avatar

                VStack(alignment: .leading, spacing: 3) {
                    Text(fullName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)

                    Text(authVM.profile?.email ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            Divider()
                .overlay(.white.opacity(0.08))

            HStack(alignment: .firstTextBaseline) {
                Label("Compte Izly", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Solde")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(authVM.balance.euroFormatted)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))

                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.accentColor.opacity(0.38),
                                Color.accentColor.opacity(0.10),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Z")
                    .font(.system(size: 190, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.05))
                    .offset(x: 26, y: -34)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
        }
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
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .frame(width: 76, height: 76)
                .clipShape(.circle)
                .overlay {
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.accentColor, .white.opacity(0.9), .accentColor],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                }

                Image(systemName: "camera.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor, in: .circle)
                    .overlay(Circle().strokeBorder(.black.opacity(0.35), lineWidth: 1.5))
                    .offset(x: 2, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Changer la photo de profil")
    }

    // MARK: - Le bilan

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ton bilan")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                StatTile(
                    icon: "arrow.up.right",
                    tint: .red,
                    value: totalSpent.euroFormatted,
                    label: "Dépensé"
                )
                StatTile(
                    icon: "arrow.down.left",
                    tint: .green,
                    value: totalTopup.euroFormatted,
                    label: "Rechargé"
                )
                StatTile(
                    icon: "fork.knife",
                    tint: .orange,
                    value: "\(mealCount)",
                    label: "Repas pris"
                )
                StatTile(
                    icon: "chart.bar.fill",
                    tint: .blue,
                    value: averagePerMeal.euroFormatted,
                    label: "Moyenne par repas"
                )
            }
        }
    }

    // MARK: - La semaine

    private var spendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cette semaine")
                .font(.headline)
                .padding(.horizontal, 4)

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
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 10) {
            Button {
                isPickerPresented = true
            } label: {
                Label("Changer la photo", systemImage: "photo")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)

            Button(role: .destructive) {
                authVM.logout()
                dismiss()
            } label: {
                Text("Se déconnecter")
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
    }

    // MARK: - Pied

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Zeru n'est pas affilié à Izly ni aux Crous.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text("Version \(appVersion)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}

// MARK: - Tuile de statistique

private struct StatTile: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glassEffect(.regular, in: .rect(cornerRadius: 18))
    }
}

// MARK: - Modèle

private struct DaySpend: Identifiable {
    let id = UUID()
    let label: String
    let amount: Double
}
