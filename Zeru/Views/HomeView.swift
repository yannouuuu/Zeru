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

    private var fullName: String {
        "\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")"
            .trimmingCharacters(in: .whitespaces)
    }

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

        // On part du solde actuel et on remonte le temps : chaque point est le
        // solde juste avant l'opération. Le dernier point est donc exactement
        // le solde affiché, ce qui évite tout décalage en fin de courbe.
        var points: [BalancePoint] = [
            BalancePoint(date: Date(), balance: authVM.balance, transaction: nil)
        ]

        var running = authVM.balance
        for transaction in filtered.reversed() {
            running -= transaction.amount
            points.append(
                BalancePoint(
                    date: Date(timeIntervalSince1970: transaction.timestamp / 1000),
                    balance: running,
                    transaction: transaction
                )
            )
        }

        return points.reversed()
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
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image("IconPreviewClassic")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                        )
                        .accessibilityHidden(true)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(fullName)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(1)

                            avatar
                        }
                        .padding(.leading, 14)
                        .padding(.trailing, 4)
                        .padding(.vertical, 4)
                        .glassEffect(.regular, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Profil de \(fullName)")
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

    private var avatar: some View {
        Group {
            if let image = authVM.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initials)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(width: 26, height: 26)
        .clipShape(.circle)
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
            BalanceChartView(
                points: cachedLineData,
                accent: .accentColor,
                selected: $selectedPoint
            )
            .frame(height: 150)
            .padding(.top, 10)
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
        case .payment:  return transactions.filter { $0.group == 0 }
        case .topup:    return transactions.filter { $0.group == 1 }
        case .transfer: return transactions.filter { $0.group == 2 }
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
    let date:        Date
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


// MARK: - Graphe du solde

/// Un graphe dessiné à la main : l'aire remplit toute la hauteur,
/// la courbe est lissée et le drag suit le doigt sans animation.
private struct BalanceChartView: View {
    let points: [BalancePoint]
    let accent: Color
    @Binding var selected: BalancePoint?

    var body: some View {
        GeometryReader { geometry in
            BalanceChartContent(
                points: points,
                accent: accent,
                selected: $selected,
                size: geometry.size
            )
        }
    }
}

private struct BalanceChartContent: View {
    let points: [BalancePoint]
    let accent: Color
    @Binding var selected: BalancePoint?
    let size: CGSize

    private let haptic = UISelectionFeedbackGenerator()

    private var width: CGFloat { size.width }
    private var height: CGFloat { size.height }

    private var minBalance: Double { points.map(\.balance).min() ?? 0 }
    private var maxBalance: Double { points.map(\.balance).max() ?? 1 }
    private var range: Double { max(0.01, maxBalance - minBalance) }

    private var startDate: Date { points.first?.date ?? Date() }
    private var endDate: Date { points.last?.date ?? Date() }
    private var timeRange: TimeInterval { max(1, endDate.timeIntervalSince(startDate)) }

    private var topInset: CGFloat { height * 0.10 }
    private var bottomInset: CGFloat { height * 0.06 }
    private var plotHeight: CGFloat { max(1, height - topInset - bottomInset) }

    private func x(for date: Date) -> CGFloat {
        CGFloat(date.timeIntervalSince(startDate) / timeRange) * width
    }

    private func y(for balance: Double) -> CGFloat {
        topInset + plotHeight * CGFloat(1 - (balance - minBalance) / range)
    }

    private var cgPoints: [CGPoint] {
        points.map { CGPoint(x: x(for: $0.date), y: y(for: $0.balance)) }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            smoothPath(cgPoints, closingTo: height)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.32), accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            smoothPath(cgPoints)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )

            if let selected {
                let px = x(for: selected.date)
                let py = y(for: selected.balance)

                Path { path in
                    path.move(to: CGPoint(x: px, y: 0))
                    path.addLine(to: CGPoint(x: px, y: height))
                }
                .stroke(
                    Color.secondary.opacity(0.35),
                    style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                )

                Circle()
                    .fill(accent)
                    .frame(width: 9, height: 9)
                    .position(x: px, y: py)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let px = max(0, min(width, value.location.x))
                    let nearest = points.min(by: {
                        abs(x(for: $0.date) - px) < abs(x(for: $1.date) - px)
                    })
                    if let nearest, selected?.id != nearest.id {
                        selected = nearest
                        haptic.selectionChanged()
                    }
                }
                .onEnded { _ in
                    selected = nil
                }
        )
    }

    /// Courbe lissée (Catmull-Rom converti en Bézier), éventuellement fermée
    /// vers le bas pour remplir l'aire sous la courbe.
    private func smoothPath(_ points: [CGPoint], closingTo bottom: CGFloat? = nil) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }

        if let bottom {
            path.move(to: CGPoint(x: points[0].x, y: bottom))
            path.addLine(to: points[0])
        } else {
            path.move(to: points[0])
        }

        for index in 0..<points.count - 1 {
            let p0 = points[max(0, index - 1)]
            let p1 = points[index]
            let p2 = points[index + 1]
            let p3 = points[min(points.count - 1, index + 2)]

            let control1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let control2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )

            path.addCurve(to: p2, control1: control1, control2: control2)
        }

        if let bottom {
            path.addLine(to: CGPoint(x: points[points.count - 1].x, y: bottom))
            path.closeSubpath()
        }

        return path
    }
}
