//
//  MenuRUView.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import SwiftUI
import CoreLocation

// MARK: - Vue principale Menu RU

struct MenuRUView: View {
    @State private var vm = CROUSViewModel()
    @State private var showRestaurantPicker = false
    @Namespace private var dateNamespace

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoadingRegions {
                    loadingView("Chargement des régions…")
                } else if vm.selectedRegion == nil {
                    noRegionView
                } else {
                    mainContent
                }
            }
            .navigationTitle("Menu du RU")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showRestaurantPicker = true
                    } label: {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 34, height: 34)
                            .glassEffect(.regular, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showRestaurantPicker) {
                RestaurantPickerSheet(vm: vm)
            }
        }
        .task {
            await vm.load()
        }
    }

    // MARK: - Contenu principal

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                restaurantCard

                if !vm.availableDates.isEmpty {
                    dateStrip
                }

                if vm.isLoadingMenus || vm.isLoadingRestaurants {
                    loadingView("Chargement du menu…")
                        .padding(.top, 40)
                } else if let error = vm.error {
                    errorView(error)
                } else if vm.mealsForSelectedDate.isEmpty {
                    noMenuView
                } else {
                    ForEach(vm.mealsForSelectedDate) { meal in
                        MealCard(meal: meal)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Carte restaurant sélectionné

    private var restaurantCard: some View {
        Button {
            showRestaurantPicker = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 3) {
                    if let restaurant = vm.selectedRestaurant {
                        Text(restaurant.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        HStack(spacing: 4) {
                            if let dist = vm.distanceLabel(for: restaurant) {
                                Label(dist, systemImage: "location.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                                Text("·")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            Text(vm.selectedRegion?.name ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Choisir un restaurant")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Appuyer pour sélectionner")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Sélecteur de date (bande horizontale)

    private var dateStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.availableDates, id: \.self) { date in
                    let isSelected = Calendar.current.isDate(date, inSameDayAs: vm.selectedDate)
                    let isToday    = Calendar.current.isDateInToday(date)

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.selectedDate = date
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(isToday ? "Auj." : date.ruWeekdayAbbrev)
                                .font(.caption2.bold())
                                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                            Text(date.ruDayNumber)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .frame(width: 52, height: 56)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
                        .glassEffectID("date-\(date.timeIntervalSince1970)", in: dateNamespace)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(
                                    isSelected ? Color.accentColor.opacity(0.6) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, -20)
    }

    // MARK: - Vues d'état

    private func loadingView(_ text: String) -> some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.2)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var noRegionView: some View {
        ContentUnavailableView {
            Label("Choisir une région", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Sélectionne ta région Crous pour voir le menu de ton RU.")
        } actions: {
            Button("Choisir") { showRestaurantPicker = true }
                .buttonStyle(.glassProminent)
        }
    }

    private var noMenuView: some View {
        ContentUnavailableView {
            Label("Pas de menu", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("Aucun menu disponible pour ce jour.\nLe restaurant est peut-être fermé.")
        }
        .padding(.top, 20)
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Erreur", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Réessayer") { Task { await vm.loadMenus() } }
                .buttonStyle(.glassProminent)
        }
        .padding(.top, 20)
    }
}

// MARK: - Carte d'un repas (Déjeuner / Dîner / Petit-déj)

private struct MealCard: View {
    let meal: CrousMeal

    var body: some View {
        VStack(spacing: 0) {
            // En-tête
            HStack(spacing: 10) {
                Image(systemName: meal.momentIcon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                Text(meal.momentLabel)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 14)

            // Message exceptionnel (fermeture, info...)
            if let info = meal.information {
                Divider()
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                    Text(info)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }

            // Catégories alimentaires
            if !meal.categories.isEmpty {
                Divider()
                VStack(spacing: 0) {
                    ForEach(Array(meal.categories.enumerated()), id: \.element.id) { idx, category in
                        FoodCategoryRow(category: category)
                        if idx < meal.categories.count - 1 {
                            Divider().padding(.leading, 18)
                        }
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Ligne d'une catégorie alimentaire

private struct FoodCategoryRow: View {
    let category: CrousFoodCategory
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Text(category.name.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(duration: 0.3), value: isExpanded)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(category.dishes, id: \.self) { dish in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 5, height: 5)
                                .padding(.top, 6)
                            Text(dish)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Sheet sélecteur de restaurant

struct RestaurantPickerSheet: View {
    let vm: CROUSViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var sortedRestaurants: [CrousRestaurant] {
        vm.restaurants.sorted { a, b in
            if let loc = vm.userLocation,
               let da = a.distance(from: loc),
               let db = b.distance(from: loc) {
                return da < db
            }
            return a.title < b.title
        }
    }

    private var filteredRestaurants: [CrousRestaurant] {
        guard !searchText.isEmpty else { return sortedRestaurants }
        return sortedRestaurants.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Région ────────────────────────────────
                Section("Région Crous") {
                    if vm.isLoadingRegions {
                        ProgressView()
                    } else {
                        regionScrollView
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                }

                // ── Restaurants ───────────────────────────
                if vm.isLoadingRestaurants {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView().padding(.vertical, 20)
                            Spacer()
                        }
                    }
                } else if let region = vm.selectedRegion {
                    let label = searchText.isEmpty
                        ? "\(region.name) — \(filteredRestaurants.count) restaurant\(filteredRestaurants.count > 1 ? "s" : "")"
                        : "\(filteredRestaurants.count) résultat\(filteredRestaurants.count > 1 ? "s" : "") pour « \(searchText) »"

                    Section(label) {
                        if filteredRestaurants.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                    Text("Aucun résultat")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                        } else {
                            ForEach(filteredRestaurants) { restaurant in
                                RestaurantRow(
                                    restaurant: restaurant,
                                    isSelected: vm.selectedRestaurant?.id == restaurant.id,
                                    distanceLabel: vm.distanceLabel(for: restaurant)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Task {
                                        await vm.selectRestaurant(restaurant)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Chercher un restaurant")
            .navigationTitle("Choisir un RU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private var regionScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.regions) { region in
                    let isSelected = vm.selectedRegion?.id == region.id
                    Button {
                        Task { await vm.selectRegion(region) }
                    } label: {
                        Text(region.name)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(isSelected ? Color.accentColor : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: Capsule())
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color.accentColor.opacity(0.5) : Color.clear,
                                    lineWidth: 1.5
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Ligne restaurant dans le picker

private struct RestaurantRow: View {
    let restaurant: CrousRestaurant
    let isSelected: Bool
    let distanceLabel: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "building.2")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(restaurant.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if let dist = distanceLabel {
                        Label(dist, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text(restaurant.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Extensions Date

extension Date {
    var ruWeekdayAbbrev: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEE"
        return f.string(from: self).capitalized
    }

    var ruDayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }
}
