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
    @Namespace private var namespace
    @State private var selectedPeriod: Period = .week
    @State private var showProfile = false

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? "?"
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    BalanceChartCard(
                        balance: authVM.balance,
                        transactions: authVM.transactions,
                        selectedPeriod: $selectedPeriod
                    )
                    .padding(.horizontal, 20)

                    TransactionHistorySection(transactions: authVM.transactions)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Accueil")
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
    }
}

// ── Carte solde + graphe ───────────────────────────────
struct BalanceChartCard: View {
    let balance: Double
    let transactions: [IzlyTransaction]
    @Binding var selectedPeriod: Period
    @State private var selectedPoint: BalancePoint? = nil
    @State private var cachedLineData: [BalancePoint] = []
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    private func buildLineData() -> [BalancePoint] {
        let sorted = transactions.sorted { $0.timestamp < $1.timestamp }
        var startBalance = balance
        for tx in sorted { startBalance -= tx.amount }
        var running = startBalance
        var points: [BalancePoint] = [
            BalancePoint(index: 0, date: "Début", balance: running, transaction: nil)
        ]
        for (i, tx) in sorted.enumerated() {
            running += tx.amount
            points.append(BalancePoint(
                index: i + 1,
                date: tx.date,
                balance: running,
                transaction: tx
            ))
        }
        return points
    }

    var totalSpent: Double {
        transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Solde ──────────────────────────────────
            VStack(spacing: 4) {
                if let point = selectedPoint {
                    Text(point.date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                    Text(point.balance.euroFormatted)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    if let tx = point.transaction {
                        Text(tx.amount.signedEuroFormatted + " · " + tx.label)
                            .font(.caption)
                            .foregroundStyle(tx.amount >= 0 ? .green : .red)
                            .transition(.opacity)
                    }
                } else {
                    Text("Solde disponible")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                    Text(balance.euroFormatted)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
            }
            .animation(.interactiveSpring(duration: 0.1), value: selectedPoint?.index)
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            // ── Sélecteur période ──────────────────────
            HStack(spacing: 0) {
                ForEach(Period.allCases, id: \.self) { period in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            selectedPeriod = period
                        }
                    } label: {
                        Text(period.label)
                            .font(.caption)
                            .fontWeight(selectedPeriod == period ? .semibold : .regular)
                            .foregroundStyle(selectedPeriod == period ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            // ── Graphe ligne ───────────────────────────
            if cachedLineData.count >= 2 {
                Chart(cachedLineData) { point in
                    AreaMark(
                        x: .value("Index", point.index),
                        y: .value("Solde", point.balance)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.3), .clear],
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
                    .lineStyle(StrokeStyle(lineWidth: 2))
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
                .frame(height: 130)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !cachedLineData.isEmpty else { return }
                            let chartWidth: CGFloat = UIScreen.main.bounds.width - 40 - 32
                            let ratio = value.location.x / chartWidth
                            let index = Int((ratio * CGFloat(cachedLineData.count - 1)).rounded())
                            let clamped = max(0, min(cachedLineData.count - 1, index))
                            let point = cachedLineData[clamped]
                            if selectedPoint?.index != point.index {
                                haptic.impactOccurred()
                                withAnimation(.interactiveSpring(duration: 0.1)) {
                                    selectedPoint = point
                                }
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(duration: 0.3)) {
                                selectedPoint = nil
                            }
                        }
                )
            } else {
                Text("Pas encore de données")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(height: 130)
            }

            Divider()

            // ── Résumé ─────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dépensé")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalSpent.euroFormatted)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(transactions.filter { $0.amount < 0 }.count)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
        .onAppear {
            haptic.prepare()
            cachedLineData = buildLineData()
        }
        .onChange(of: transactions) { _, _ in
            cachedLineData = buildLineData()
        }
    }
}

// ── Section historique ─────────────────────────────────
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
