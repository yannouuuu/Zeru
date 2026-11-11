//
//  HomeHeroIdeas.swift
//  Zeru
//
//  Quatre idées natives pour l'accueil (solde + graphe), avec l'interaction
//  de drag. Fichier de prévisualisation : ouvre-le dans Xcode et lance le
//  canvas pour interagir avec chaque idée.
//

#if DEBUG
import SwiftUI
import Charts

// MARK: - Données de démonstration

struct HeroDemoPoint: Identifiable {
    let id = UUID()
    let index: Int
    let label: String
    let balance: Double
    let amount: Double?
}

enum HeroDemoData {
    static let balance: Double = 24.50

    static let points: [HeroDemoPoint] = {
        let amounts: [Double] = [-3.30, 20.00, -3.30, 10.00, -3.30, -2.40, -3.30, -1.10, -3.30, 15.00, -1.50, -3.30]
        var running = 12.85
        var points: [HeroDemoPoint] = [
            HeroDemoPoint(index: 0, label: "18/10", balance: running, amount: nil)
        ]
        for (i, amount) in amounts.enumerated() {
            running = max(0, running + amount)
            points.append(
                HeroDemoPoint(index: i + 1, label: "\(20 + i)/10", balance: running, amount: amount)
            )
        }
        points.append(
            HeroDemoPoint(index: points.count, label: "Maintenant", balance: balance, amount: nil)
        )
        return points
    }()
}

// MARK: - Le graphe avec le drag

struct HeroDragChart: View {
    let points: [HeroDemoPoint]
    let accent: Color
    @Binding var selected: HeroDemoPoint?

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Index", point.index),
                y: .value("Solde", point.balance)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [accent.opacity(0.28), accent.opacity(0.01)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("Index", point.index),
                y: .value("Solde", point.balance)
            )
            .foregroundStyle(accent)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .interpolationMethod(.catmullRom)

            if let selected, selected.index == point.index {
                PointMark(
                    x: .value("Index", point.index),
                    y: .value("Solde", point.balance)
                )
                .symbolSize(80)
                .foregroundStyle(accent)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let frame = proxy.plotFrame else { return }
                                let origin = geo[frame].origin.x
                                let width = geo[frame].width
                                guard width > 0 else { return }
                                let ratio = max(0, min(1, (value.location.x - origin) / width))
                                let index = Int((ratio * CGFloat(points.count - 1)).rounded())
                                let point = points[max(0, min(points.count - 1, index))]
                                if selected?.index != point.index {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    withAnimation(.snappy(duration: 0.12)) { selected = point }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.snappy) { selected = nil }
                            }
                    )
            }
        }
    }
}

// MARK: - Idée 1 : le solde est le titre

struct HeroIdeaOne: View {
    @State private var selected: HeroDemoPoint?
    @State private var period = 1
    private let points = HeroDemoData.points

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Solde disponible")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(selected?.balance.euroFormatted ?? HeroDemoData.balance.euroFormatted)
                                .font(.system(size: 62, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())

                            if selected == nil {
                                Text("7 repas")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary, in: .capsule)
                            }
                        }
                        .animation(.snappy(duration: 0.15), value: selected?.index)

                        Text(selectedCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    HeroDragChart(points: points, accent: .accentColor, selected: $selected)
                        .frame(height: 150)
                        .padding(.top, 10)

                    Picker("Période", selection: $period) {
                        Text("7 jours").tag(0)
                        Text("30 jours").tag(1)
                        Text("1 an").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    HeroSummaryRow()
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                    Text("Historique")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var selectedCaption: String {
        if let selected, let amount = selected.amount {
            return "\(amount.signedEuroFormatted) · \(selected.label)"
        }
        return "7 repas au RU · 3,30 € le repas"
    }
}

// MARK: - Idée 2 : le graphe derrière le solde

struct HeroIdeaTwo: View {
    @State private var selected: HeroDemoPoint?
    @State private var period = 1
    private let points = HeroDemoData.points

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        HeroDragChart(points: points, accent: .accentColor, selected: $selected)
                            .frame(height: 250)
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .clear, location: 0),
                                        .init(color: .black, location: 0.35)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.top, 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Solde disponible")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text(selected?.balance.euroFormatted ?? HeroDemoData.balance.euroFormatted)
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())

                            Text(selectedCaption)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .frame(height: 290)

                    Picker("Période", selection: $period) {
                        Text("7 jours").tag(0)
                        Text("30 jours").tag(1)
                        Text("1 an").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)

                    HeroSummaryRow()
                        .padding(.horizontal, 20)
                        .padding(.top, 18)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var selectedCaption: String {
        if let selected, let amount = selected.amount {
            return "\(amount.signedEuroFormatted) · \(selected.label)"
        }
        return "7 repas au RU"
    }
}

// MARK: - Idée 3 : la carte respire

struct HeroIdeaThree: View {
    @State private var selected: HeroDemoPoint?
    @State private var period = 1
    private let points = HeroDemoData.points

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bonjour Camille")
                            .font(.title3.weight(.semibold))
                        Text("mardi 11 novembre")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    VStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text(selected?.label ?? "Solde disponible")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selected?.balance.euroFormatted ?? HeroDemoData.balance.euroFormatted)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                        Divider()

                        Picker("Période", selection: $period) {
                            Text("7 jours").tag(0)
                            Text("30 jours").tag(1)
                            Text("1 an").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        HeroDragChart(points: points, accent: .accentColor, selected: $selected)
                            .frame(height: 130)
                            .padding(.top, 8)

                        Divider()

                        HeroSummaryRow()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                    }
                    .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    .padding(.horizontal, 20)

                    Text("Historique")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Idée 4 : le bandeau compact

struct HeroIdeaFour: View {
    @State private var selected: HeroDemoPoint?
    @State private var period = 1
    private let points = HeroDemoData.points

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Solde disponible")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(selected?.balance.euroFormatted ?? HeroDemoData.balance.euroFormatted)
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())
                        }

                        Spacer()

                        Text("7 repas")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    HeroDragChart(points: points, accent: .accentColor, selected: $selected)
                        .frame(height: 66)
                        .padding(.top, 8)

                    if let selected, let amount = selected.amount {
                        Text("\(amount.signedEuroFormatted) · \(selected.label)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    }

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    Text("Historique")
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Accueil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("7 jours") { period = 0 }
                        Button("30 jours") { period = 1 }
                        Button("1 an") { period = 2 }
                    } label: {
                        Text("30 jours")
                            .font(.subheadline.weight(.medium))
                    }
                }
            }
        }
    }
}

// MARK: - Résumé commun

private struct HeroSummaryRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Dépensé")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("18,20 €")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("7")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Prévisualisations

#Preview("1 · Le solde est le titre") {
    HeroIdeaOne()
}

#Preview("2 · Le graphe derrière le solde") {
    HeroIdeaTwo()
}

#Preview("3 · La carte respire") {
    HeroIdeaThree()
}

#Preview("4 · Le bandeau compact") {
    HeroIdeaFour()
}
#endif
