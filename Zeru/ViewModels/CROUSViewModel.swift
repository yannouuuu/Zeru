//
//  CROUSViewModel.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import Foundation
import CoreLocation
import Observation

// MARK: - ViewModel principal pour le menu du RU

@MainActor
@Observable
final class CROUSViewModel: NSObject {

    // MARK: - Données

    var regions: [CrousRegion] = []
    var restaurants: [CrousRestaurant] = []
    var menus: [CrousMenu] = []

    // MARK: - Sélections

    var selectedRegion: CrousRegion? {
        didSet { UserDefaults.standard.set(selectedRegion?.id, forKey: "crous.selectedRegionId") }
    }
    var selectedRestaurant: CrousRestaurant? {
        didSet {
            if let r = selectedRestaurant {
                UserDefaults.standard.set(r.id, forKey: "crous.selectedRestaurantId")
            }
        }
    }
    var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - États de chargement

    var isLoadingRegions    = false
    var isLoadingRestaurants = false
    var isLoadingMenus      = false
    var error: String?

    // MARK: - Localisation

    private let locationManager = CLLocationManager()
    var userLocation: CLLocation?
    var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined

    // MARK: - Init

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    // MARK: - Chargement initial

    func load() async {
        requestLocation()
        await loadRegions()
    }

    func loadRegions() async {
        isLoadingRegions = true
        error = nil
        do {
            regions = try await CROUSService.fetchRegions()
            regions.sort { $0.name < $1.name }

            // Restauration de la région sauvegardée
            if let savedId = UserDefaults.standard.string(forKey: "crous.selectedRegionId"),
               let saved = regions.first(where: { $0.id == savedId }) {
                selectedRegion = saved
                await loadRestaurants()
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingRegions = false
    }

    func selectRegion(_ region: CrousRegion) async {
        selectedRegion = region
        selectedRestaurant = nil
        menus = []
        await loadRestaurants()
    }

    func loadRestaurants() async {
        guard let region = selectedRegion else { return }
        isLoadingRestaurants = true
        error = nil
        do {
            restaurants = try await CROUSService.fetchRestaurants(for: region.id)

            // Restauration du restaurant sauvegardé
            let savedId = UserDefaults.standard.integer(forKey: "crous.selectedRestaurantId")
            if savedId != 0, let saved = restaurants.first(where: { $0.id == savedId }) {
                selectedRestaurant = saved
            } else {
                // Sélection automatique du plus proche (ou premier si pas de position)
                selectedRestaurant = nearestRestaurant() ?? restaurants.first
            }

            if selectedRestaurant != nil {
                await loadMenus()
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingRestaurants = false
    }

    func selectRestaurant(_ restaurant: CrousRestaurant) async {
        selectedRestaurant = restaurant
        menus = []
        await loadMenus()
    }

    func loadMenus() async {
        guard let region = selectedRegion,
              let restaurant = selectedRestaurant else { return }
        isLoadingMenus = true
        error = nil
        do {
            menus = try await CROUSService.fetchAllMenus(
                for: region.id,
                restaurantId: restaurant.id
            )
            selectBestDate()
        } catch {
            self.error = error.localizedDescription
        }
        isLoadingMenus = false
    }

    // Sélectionne aujourd'hui si disponible, sinon la prochaine date à venir
    private func selectBestDate() {
        let today = Calendar.current.startOfDay(for: Date())
        let best = availableDates.first(where: { $0 >= today }) ?? availableDates.last
        if let best {
            selectedDate = best
        }
    }

    // MARK: - Menus du jour sélectionné

    var mealsForSelectedDate: [CrousMeal] {
        guard let menu = menus.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }) else { return [] }
        return menu.meals.sorted { $0.momentOrder < $1.momentOrder }
    }

    var availableDates: [Date] {
        menus.map { $0.date }.sorted()
    }

    // MARK: - Localisation

    func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            break
        }
    }

    func nearestRestaurant() -> CrousRestaurant? {
        guard let location = userLocation else { return nil }
        return restaurants
            .compactMap { r -> (CrousRestaurant, CLLocationDistance)? in
                guard let d = r.distance(from: location) else { return nil }
                return (r, d)
            }
            .min(by: { $0.1 < $1.1 })?
            .0
    }

    func distanceLabel(for restaurant: CrousRestaurant) -> String? {
        guard let location = userLocation,
              let dist = restaurant.distance(from: location) else { return nil }
        if dist < 1000 {
            return "\(Int(dist)) m"
        } else {
            return String(format: "%.1f km", dist / 1000)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension CROUSViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor in
            self.userLocation = loc
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Pas critique : on continuera sans localisation
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.locationAuthorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
