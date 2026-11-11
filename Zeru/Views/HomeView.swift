//
//  HomeView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import Charts

struct HomeView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var selectedPeriod: Period = .month
    @State private var showProfile = false
    @State private var selectedPoint: BalancePoint?
    @State private var cachedLineData: [BalancePoint] = []
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? "?"
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    private var mealsRemaining: Int {
        max(0, Int(authVM.balance / 3.30))
    }

    private var cutoffDate: Date {
        let now = Date()
        switch selectedPeriod {
        case .week:
            return Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }

    private var filteredTransactions: [IzlyTransaction] {
        authVM.transactions.filter {
            Date(timeIntervalSince1970: $0.timestamp / 1000) >= cutoffDate
        }
    }

    private var totalSpent: Double {
        filteredTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }

    private var transactionCount: Int {
        filteredTransactions.filter { $0.amount < 0 }.count
    }

    private var heroCaption: String {
        if let selectedPoint, let transaction = selectedPoint.transaction {
            return "\(transaction.amount.signedEuroFormatted) · \(transaction.label)"
        }
        return "\(mealsRemaining) repas au RU · 3,30 € le repas"
    }

    private func buildLineData() -> [BalancePoint] {
        let filtered = filteredTransactions.sorted { $0.timestamp < $1.timestamp }
        guard !filtered.isEmpty else { return [] }

        let periodSum = filtered.reduce(0.0) { $0 + $1.amount }
        var running = max(0, authVM.balance - periodSum)

        var points: [BalancePoint] = [
            BalancePoint(
                index: 0,
                date: formatPointDate(cutoffDate),
                balance: running,
                transaction: nil
            )
        ]

        for (index, transaction) in filtered.enumerated() {
            running = max(0, running + transaction.amount)
            points.append(
                BalancePoint(
                    index: index + 1,
                    date: transaction.date,
                    balance: running,
                    transaction: transaction
                )
            )
        }

        points.append(
            BalancePoint(
                index: points.count,
                date: "Maintenant",
                balance: authVM.balance,
                transaction: nil
            )
        )
        return points
    }

    private func formatPointDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Corps

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero
                    chartSection
                    periodPicker
                    summary

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                    TransactionHistorySection(transactions: authVM.transactions)
                        .padding(.top, 16)
                }
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        if let image = authVM.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 34, height: 34)
                                .clipShape(.circle)
                                .glassEffect(.regular, in: .circle)
                        } else {
                            Text(initials)
                                .font(.system(size: 14, weight: .semibold))
                                .frame(width: 34, height: 34)
                                .glassEffect(.regular, in: .circle)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileSheetView(authVM: authVM)
            }
        }
        .task {
            await authVM.loadTransactions()
        }
        .onAppear {
            haptic.prepare()
            cachedLineData = buildLineData()
        }
        .onChange(of: authVM.transactions) { _, _ in
            cachedLineData = buildLineData()
        }
        .onChange(of: selectedPeriod) { _, _ in
            withAnimation(.snappy) {
                cachedLineData = buildLineData()
                selectedPoint = nil
            }
        }
    }

    // MARK: - Le solde

    private var hero: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Solde disponible")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(selectedPoint?.balance.euroFormatted ?? authVM.balance.euroFormatted)
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: selectedPoint?.index)
                    .animation(.snappy, value: authVM.balance)

                if selectedPoint == nil {
                    Text("\(mealsRemaining) repas")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: .capsule)
                }
            }

            Text(heroCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Le graphe

    @ViewBuilder
    private var chartSection: some View {
        if cachedLineData.count >= 2 {
            Chart(cachedLineData) { point in
                AreaMark(
                    x: .value("Index", point.index),
                    y: .value("Solde", point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.28), Color.accentColor.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Index", point.index),
                    y: .value("Solde", point.balance)
                )
                .foregroundStyle(Color.accentColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.catmullRom)

                if let selected = selectedPoint, selected.index == point.index {
                    PointMark(
                        x: .value("Index", point.index),
                        y: .value("Solde", point.balance)
                    )
                    .symbolSize(80)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 150)
            .padding(.top, 10)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let origin = geometry[plotFrame].origin.x
                                    let width = geometry[plotFrame].width
                                    guard width > 0 else { return }
                                    let ratio = max(0, min(1, (value.location.x - origin) / width))
                                    let index = Int((ratio * CGFloat(cachedLineData.count - 1)).rounded())
                                    let point = cachedLineData[max(0, min(cachedLineData.count - 1, index))]
                                    if selectedPoint?.index != point.index {
                                        haptic.impactOccurred()
                                        withAnimation(.snappy(duration: 0.12)) {
                                            selectedPoint = point
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.snappy) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                }
            }
        } else {
            Text("Pas encore de données sur cette période")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .padding(.top, 10)
        }
    }

    // MARK: - Période

    private var periodPicker: some View {
        Picker("Période", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.label).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Résumé

    private var summary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dépensé")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(totalSpent.euroFormatted)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(transactionCount)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }
}

struct TransactionHistorySection: View {
    let transactions: [IzlyTransaction]
    @State private var filter: TransactionFilter = .all
    @Namespace private var filterNamespace

    var filtered: [IzlyTransaction] {
        switch filter {
        case .all:      return transactions
        case .payment:  return transactions.filter { $0.group == 2 }
        case .topup:    return transactions.filter { $0.group == 0 }
        case .transfer: return transactions.filter { $0.group == 1 }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("Historique")
                .font(.headline)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionFilter.allCases, id: \.self) { f in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                filter = f
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: f.icon)
                                    .font(.caption.bold())
                                Text(f.label)
                                    .font(.subheadline)
                                    .fontWeight(filter == f ? .semibold : .regular)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                filter == f
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.primary.opacity(0.05),
                                in: Capsule()
                            )
                            .glassEffect(.regular, in: Capsule())
                            .glassEffectID(f.rawValue, in: filterNamespace)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }

            if filtered.isEmpty {
                ContentUnavailableView(
                    "Aucune transaction",
                    systemImage: filter.icon,
                    description: Text("Aucune \(filter.label.lowercased()) pour l'instant")
                )
                .padding(.vertical, 12)
            } else {
                GlassEffectContainer(spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(filtered) { tx in
                            TransactionRow(transaction: tx)
                            if tx.id != filtered.last?.id {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .animation(.spring(duration: 0.35), value: filter)
            }
        }
    }
}

// ── Ligne transaction ──────────────────────────────────
struct TransactionRow: View {
    let transaction: IzlyTransaction

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: transaction.amount >= 0
                  ? "arrow.down.circle.fill"
                  : "fork.knife.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(transaction.amount >= 0 ? .green : Color.accentColor)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(transaction.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(transaction.amount.signedEuroFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(transaction.amount >= 0 ? .green : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// ── Modèles ────────────────────────────────────────────
struct BalancePoint: Identifiable {
    let id          = UUID()
    let index:       Int
    let date:        String
    let balance:     Double
    let transaction: IzlyTransaction?
}

enum Period: String, CaseIterable {
    case week  = "week"
    case month = "month"
    case year  = "year"

    var label: String {
        switch self {
        case .week:  return "7 jours"
        case .month: return "30 jours"
        case .year:  return "1 an"
        }
    }
}

enum TransactionFilter: String, CaseIterable {
    case all      = "all"
    case payment  = "payment"
    case topup    = "topup"
    case transfer = "transfer"

    var label: String {
        switch self {
        case .all:      return "Tout"
        case .payment:  return "Paiements"
        case .topup:    return "Rechargements"
        case .transfer: return "Virements"
        }
    }

    var icon: String {
        switch self {
        case .all:      return "list.bullet"
        case .payment:  return "fork.knife"
        case .topup:    return "plus.circle"
        case .transfer: return "arrow.up.arrow.down"
        }
    }
}
