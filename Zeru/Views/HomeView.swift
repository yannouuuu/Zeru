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
    @State private var crosshair: CGPoint?
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

    private var captionColor: Color {
        guard let transaction = selectedPoint?.transaction else { return .secondary }
        return transaction.amount >= 0 ? .green : .red
    }

    private func buildLineData() -> [BalancePoint] {
        let filtered = filteredTransactions.sorted { $0.timestamp < $1.timestamp }
        guard !filtered.isEmpty else { return [] }

        // Solde de départ = solde actuel - somme des transactions de la période.
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

        for (offset, transaction) in filtered.enumerated() {
            running += transaction.amount
            running = max(0, running) // Izly ne peut pas être négatif
            points.append(
                BalancePoint(
                    index: offset + 1,
                    date: transaction.date,
                    balance: running,
                    transaction: transaction
                )
            )
        }

        // Dernier point = solde réel actuel.
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
            Text(selectedPoint?.date ?? "Solde disponible")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.snappy(duration: 0.12), value: selectedPoint?.id)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(selectedPoint?.balance.euroFormatted ?? authVM.balance.euroFormatted)
                    .font(.system(size: 62, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.12), value: selectedPoint?.id)

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
                .foregroundStyle(captionColor)
                .lineLimit(1)
                .animation(.snappy(duration: 0.12), value: selectedPoint?.id)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    // MARK: - Le graphe

    private func screenPoints(proxy: ChartProxy) -> [CGPoint] {
        cachedLineData.compactMap { point in
            guard let x = proxy.position(forX: point.index),
                  let y = proxy.position(forY: point.balance) else { return nil }
            return CGPoint(x: x, y: y)
        }
    }

    /// Évalue la courbe (Catmull-Rom) à une abscisse donnée, en coordonnées écran.
    private func curveY(at x: CGFloat, points: [CGPoint]) -> CGFloat? {
        guard points.count > 1 else { return nil }

        let clampedX = max(points[0].x, min(points[points.count - 1].x, x))

        var segment = 0
        while segment < points.count - 2 && points[segment + 1].x < clampedX {
            segment += 1
        }

        let p0 = points[max(0, segment - 1)]
        let p1 = points[segment]
        let p2 = points[segment + 1]
        let p3 = points[min(points.count - 1, segment + 2)]

        let dx = p2.x - p1.x
        let t = dx == 0 ? 0 : (clampedX - p1.x) / dx
        let t2 = t * t
        let t3 = t2 * t

        return 0.5 * (
            2 * p1.y
            + (-p0.y + p2.y) * t
            + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
            + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3
        )
    }

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
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 150)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    let plot = proxy.plotFrame.map { geometry[$0] } ?? .zero

                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(.clear)
                            .contentShape(Rectangle())

                        if let crosshair {
                            Path { path in
                                path.move(to: CGPoint(x: crosshair.x, y: plot.minY))
                                path.addLine(to: CGPoint(x: crosshair.x, y: plot.maxY))
                            }
                            .stroke(
                                Color.secondary.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1, dash: [3, 3])
                            )

                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 9, height: 9)
                                .position(x: crosshair.x, y: crosshair.y)
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let frame = proxy.plotFrame else { return }
                                let plotRect = geometry[frame]
                                guard plotRect.width > 0 else { return }

                                let x = max(plotRect.minX, min(plotRect.maxX, value.location.x))
                                let screenPoints = self.screenPoints(proxy: proxy)
                                guard let curveY = self.curveY(at: x, points: screenPoints) else { return }

                                crosshair = CGPoint(x: x, y: curveY)

                                let ratio = (x - plotRect.minX) / plotRect.width
                                let index = Int((ratio * CGFloat(cachedLineData.count - 1)).rounded())
                                let clamped = max(0, min(cachedLineData.count - 1, index))
                                let point = cachedLineData[clamped]

                                if selectedPoint?.index != point.index {
                                    haptic.impactOccurred()
                                    selectedPoint = point
                                }
                            }
                            .onEnded { _ in
                                crosshair = nil
                                selectedPoint = nil
                            }
                    )
                }
            }
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


