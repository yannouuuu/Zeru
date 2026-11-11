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
    @Namespace private var restaurantCardNamespace
    @State private var carouselDate: Date?
    @State private var isRestaurantCardExpanded = false
    
    private var carouselHeight: CGFloat {
        let maxHeight = vm.availableDates
            .map { estimatedPageHeight(for: displayMeals(for: $0)) }
            .max() ?? 320
        return min(max(360, maxHeight), 1200)
    }

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
            .navigationTitle("Menu")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ruDropdownButton
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        selectNearestRestaurantIfPossible()
                    } label: {
                        Image(systemName: "location.fill")
                    }
                    .disabled(!canSelectNearestRestaurant)

                    Button {
                        jumpToTodayIfPossible()
                    } label: {
                        Label("Auj.", systemImage: "calendar.badge.clock")
                            .labelStyle(.titleAndIcon)
                            .font(.caption.weight(.semibold))
                    }
                    .disabled(!canJumpToReferenceDate)
                }
            }
            .sheet(isPresented: $showRestaurantPicker) {
                RestaurantPickerSheet(vm: vm)
            }
        }
        .task {
            await vm.load()
        }
        .onChange(of: showRestaurantPicker) { _, isPresented in
            if !isPresented {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    isRestaurantCardExpanded = false
                }
            }
        }
    }

    // MARK: - Contenu principal

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !vm.availableDates.isEmpty {
                    dateStrip
                    dayCarousel
                }

                if vm.isLoadingMenus || vm.isLoadingRestaurants {
                    loadingView("Chargement du menu…")
                        .padding(.top, 40)
                } else if let error = vm.error {
                    errorView(error)
                } else if vm.availableDates.isEmpty {
                    noMenuView
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Carte restaurant sélectionné

    private var restaurantSelector: some View {
        VStack(spacing: 0) {
            if isRestaurantCardExpanded {
                expandedRestaurantCard
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .scale(scale: 0.92, anchor: .top))
                                .combined(with: .opacity),
                            removal: .move(edge: .top)
                                .combined(with: .scale(scale: 0.95, anchor: .top))
                                .combined(with: .opacity)
                        )
                    )
            } else {
                HStack {
                    Spacer()
                    collapsedRestaurantPill
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .top).combined(with: .opacity),
                                removal: .scale(scale: 0.9, anchor: .topTrailing).combined(with: .opacity)
                            )
                        )
                }
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isRestaurantCardExpanded)
    }
    
    private var collapsedRestaurantPill: some View {
        Button {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) {
                isRestaurantCardExpanded = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(vm.selectedRestaurant?.title ?? "Choisir un RU")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Image(systemName: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule())
            .matchedGeometryEffect(id: "restaurant-selector", in: restaurantCardNamespace)
        }
        .buttonStyle(.plain)
    }
    
    private var expandedRestaurantCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 30))
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

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                    isRestaurantCardExpanded = false
                }
            } label: {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18))
        .matchedGeometryEffect(id: "restaurant-selector", in: restaurantCardNamespace)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture {
            showRestaurantPicker = true
        }
    }

    // MARK: - Toolbar RU

    private var ruDropdownButton: some View {
        Button {
            showRestaurantPicker = true
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.accentColor)

                Text(vm.selectedRestaurant?.title ?? "Choisir un RU")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(minWidth: 120, maxWidth: 220, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var referenceDate: Date? {
        guard !vm.availableDates.isEmpty else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return vm.availableDates.first(where: { $0 >= today }) ?? vm.availableDates.last
    }

    private var canJumpToReferenceDate: Bool {
        guard let target = referenceDate else { return false }
        return !Calendar.current.isDate(target, inSameDayAs: vm.selectedDate)
    }

    private func jumpToTodayIfPossible() {
        guard let today = referenceDate else { return }
        withAnimation(.spring(duration: 0.3)) {
            vm.selectedDate = today
        }
    }

    private var canSelectNearestRestaurant: Bool {
        guard let nearest = vm.nearestRestaurant() else { return false }
        guard let selected = vm.selectedRestaurant else { return true }
        return nearest.id != selected.id
    }

    private func selectNearestRestaurantIfPossible() {
        guard let nearest = vm.nearestRestaurant() else { return }
        Task {
            await vm.selectRestaurant(nearest)
        }
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
    
    private var dayCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 22) {
                ForEach(vm.availableDates, id: \.self) { date in
                    DayMenuPage(
                        date: date,
                        meals: displayMeals(for: date)
                    )
                    .id(date)
                    .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: 22)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.62)
                            .scaleEffect(phase.isIdentity ? 1 : 0.94)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 22, for: .scrollContent)
        .frame(height: carouselHeight, alignment: .top)
        .scrollPosition(id: $carouselDate)
        .onAppear {
            if carouselDate == nil {
                carouselDate = vm.selectedDate
            }
        }
        .onChange(of: vm.selectedDate) { _, newDate in
            guard !Calendar.current.isDate(newDate, inSameDayAs: carouselDate ?? .distantPast) else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                carouselDate = newDate
            }
        }
        .onChange(of: carouselDate) { _, newDate in
            guard let newDate else { return }
            guard !Calendar.current.isDate(newDate, inSameDayAs: vm.selectedDate) else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                vm.selectedDate = newDate
            }
        }
    }
    
    private func displayMeals(for date: Date) -> [CrousMeal] {
        guard let menu = vm.menus.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: date)
        }) else { return [] }
        
        return menu.meals
            .sorted { $0.momentOrder < $1.momentOrder }
            .filter { meal in
                let hasInfo = !(meal.information?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                let hasCategories = !meal.categories.isEmpty
                return hasInfo || hasCategories
            }
    }
    
    private func estimatedPageHeight(for meals: [CrousMeal]) -> CGFloat {
        guard !meals.isEmpty else { return 320 }
        
        var total: CGFloat = 80
        for meal in meals {
            let dishCount = meal.categories.reduce(0) { $0 + $1.dishes.count }
            let infoHeight: CGFloat = (meal.information?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ? 42 : 0
            let categoryHeaders = CGFloat(meal.categories.count) * 24
            let dishesHeight = CGFloat(dishCount) * 24
            total += 56 + infoHeight + categoryHeaders + dishesHeight + 18
        }
        
        return total + CGFloat(max(0, meals.count - 1)) * 10
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
            Label("Rien ce jour", systemImage: "calendar.badge.exclamationmark")
        } description: {
            Text("Aucun repas publié pour ce jour.\nC'est fréquent le samedi et le dimanche.")
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

private struct DayMenuPage: View {
    let date: Date
    let meals: [CrousMeal]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if meals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundStyle(.secondary)
                        Text("Rien ce jour")
                            .fontWeight(.semibold)
                    }
                    Text("Aucun repas publié pour ce jour. C'est fréquent le samedi et le dimanche.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            } else {
                ForEach(Array(meals.enumerated()), id: \.element.id) { index, meal in
                    MealEditorialSection(meal: meal)
                    if index < meals.count - 1 {
                        Divider().padding(.leading, 18)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MealEditorialSection: View {
    let meal: CrousMeal

    private var toneColor: Color {
        switch meal.moment {
        case "matin": return .orange
        case "midi": return .accentColor
        case "soir": return .indigo
        default: return .accentColor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: meal.momentIcon)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(toneColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.momentLabel)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("\(meal.categories.count) catégorie\(meal.categories.count > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if let info = meal.information,
               !info.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                    Text(info)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            ForEach(meal.categories) { category in
                MealCategorySection(category: category, toneColor: toneColor)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct MealCategorySection: View {
    let category: CrousFoodCategory
    let toneColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.name.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(toneColor)
            
            LazyVStack(alignment: .leading, spacing: 6) {
                ForEach(category.dishes, id: \.self) { dish in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(toneColor)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(dish)
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.leading, 2)
        }
    }
}

// MARK: - Sheet sélecteur de restaurant

private enum RestaurantSortMode: String, CaseIterable {
    case nearby
    case alphabetical

    var label: String {
        switch self {
        case .nearby: return "Autour de moi"
        case .alphabetical: return "A à Z"
        }
    }
}

struct RestaurantPickerSheet: View {
    let vm: CROUSViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var showRegionPicker = false
    @State private var sortMode: RestaurantSortMode = .nearby

    private var sortedRestaurants: [CrousRestaurant] {
        switch sortMode {
        case .nearby:
            guard let loc = vm.userLocation else {
                return vm.restaurants.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            }
            return vm.restaurants.sorted { a, b in
                let da = a.distance(from: loc)
                let db = b.distance(from: loc)

                switch (da, db) {
                case let (lhs?, rhs?):
                    if lhs != rhs { return lhs < rhs }
                    return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                default:
                    return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
                }
            }
        case .alphabetical:
            return vm.restaurants.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
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
                        regionSelectionRow
                    }
                }
                
                if !vm.isLoadingRestaurants, vm.selectedRegion != nil {
                    Section("Tri") {
                        Picker("Tri", selection: $sortMode) {
                            ForEach(RestaurantSortMode.allCases, id: \.self) { mode in
                                Text(mode.label).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
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
            .animation(.spring(duration: 0.3), value: vm.selectedRegion?.id)
            .animation(.spring(duration: 0.3), value: filteredRestaurants.count)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showRegionPicker) {
                RegionPickerSheet(vm: vm)
            }
        }
    }

    private var regionSelectionRow: some View {
        Button {
            showRegionPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.selectedRegion?.name ?? "Choisir une région")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if vm.isLoadingRestaurants {
                        Text("Chargement des restaurants…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(vm.restaurants.count) restaurant\(vm.restaurants.count > 1 ? "s" : "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private struct RegionPickerSheet: View {
    let vm: CROUSViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @AppStorage("crous.recentRegionIds") private var recentRegionIdsStorage = ""

    private var recentRegionIds: [String] {
        recentRegionIdsStorage
            .split(separator: ",")
            .map(String.init)
    }

    private var filteredRegions: [CrousRegion] {
        guard !searchText.isEmpty else { return vm.regions }
        return vm.regions.filter { region in
            region.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentRegions: [CrousRegion] {
        recentRegionIds.compactMap { id in
            vm.regions.first(where: { $0.id == id })
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let selectedRegion = vm.selectedRegion {
                    Section("Région actuelle") {
                        RegionChoiceRow(
                            region: selectedRegion,
                            isSelected: true
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismiss()
                        }
                    }
                }

                if !recentRegions.isEmpty {
                    Section("Récentes") {
                        ForEach(recentRegions) { region in
                            regionRow(region)
                        }
                    }
                }

                Section("Toutes les régions") {
                    if filteredRegions.isEmpty {
                        HStack {
                            Spacer()
                            Text("Aucune région trouvée")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                    } else {
                        ForEach(filteredRegions) { region in
                            regionRow(region)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Chercher une région Crous")
            .navigationTitle("Choisir une région")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func regionRow(_ region: CrousRegion) -> some View {
        let isSelected = vm.selectedRegion?.id == region.id

        return RegionChoiceRow(region: region, isSelected: isSelected)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isSelected else {
                    dismiss()
                    return
                }

                Task {
                    await vm.selectRegion(region)
                    updateRecentRegions(with: region.id)
                    dismiss()
                }
            }
    }

    private func updateRecentRegions(with regionId: String) {
        var ids = recentRegionIds.filter { $0 != regionId }
        ids.insert(regionId, at: 0)
        if ids.count > 6 {
            ids = Array(ids.prefix(6))
        }
        recentRegionIdsStorage = ids.joined(separator: ",")
    }
}

private struct RegionChoiceRow: View {
    let region: CrousRegion
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "mappin.circle")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .frame(width: 24)

            Text(region.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 4)
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
    
    var ruLongLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Aujourd'hui" }
        if calendar.isDateInTomorrow(self) { return "Demain" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEE d MMMM"
        return f.string(from: self).capitalized
    }
}
