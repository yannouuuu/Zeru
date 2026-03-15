//
//  CROUSModels.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import Foundation
import CoreLocation

// MARK: - Région (Feed Crous)

struct CrousRegion: Codable, Identifiable, Hashable {
    let id: String      // ex: "bordeaux"
    let name: String    // ex: "Bordeaux"
}

// MARK: - Restaurant

struct CrousRestaurant: Identifiable, Hashable {
    let id: Int
    let title: String
    let address: String
    let shortDescription: String
    let latitude: Double?
    let longitude: Double?
    let opening: String

    func distance(from location: CLLocation) -> CLLocationDistance? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return location.distance(from: CLLocation(latitude: lat, longitude: lon))
    }

    var formattedDistance: String? {
        return nil
    }

    static func == (lhs: CrousRestaurant, rhs: CrousRestaurant) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Menu (par date)

struct CrousMenu: Identifiable {
    var id: String { "\(date.timeIntervalSince1970)" }
    let date: Date
    let meals: [CrousMeal]
}

// MARK: - Repas (moment de la journée)

struct CrousMeal: Identifiable {
    let id = UUID()
    let moment: String      // "midi", "soir", "matin"
    let categories: [CrousFoodCategory]
    let information: String?

    var momentLabel: String {
        switch moment {
        case "midi":  return "Déjeuner"
        case "soir":  return "Dîner"
        case "matin": return "Petit-déjeuner"
        default:      return moment.capitalized
        }
    }

    var momentIcon: String {
        switch moment {
        case "midi":  return "sun.max.fill"
        case "soir":  return "moon.stars.fill"
        case "matin": return "sunrise.fill"
        default:      return "fork.knife"
        }
    }

    var momentOrder: Int {
        switch moment {
        case "matin": return 0
        case "midi":  return 1
        case "soir":  return 2
        default:      return 3
        }
    }
}

// MARK: - Catégorie alimentaire

struct CrousFoodCategory: Identifiable {
    let id = UUID()
    let name: String
    let dishes: [String]
}

// MARK: - Erreurs

enum CROUSError: Error, LocalizedError {
    case networkError(String)
    case parseError
    case noRestaurantFound
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .networkError(let msg): return "Erreur réseau : \(msg)"
        case .parseError:            return "Impossible de lire les données du Crous"
        case .noRestaurantFound:     return "Aucun restaurant trouvé"
        case .locationUnavailable:   return "Localisation non disponible"
        }
    }
}
