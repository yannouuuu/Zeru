//
//  CROUSService.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import Foundation
import CoreLocation

// MARK: - Service d'accès à l'API Crous Mobile
// Basé sur https://github.com/Vexcited/Crowous.js

enum CROUSService {
    private static let baseURL = "http://webservices-v2.crous-mobile.fr/feed/"

    // MARK: - Régions (feeds)

    static func fetchRegions() async throws -> [CrousRegion] {
        guard let url = URL(string: baseURL + "feeds.json") else {
            throw CROUSError.networkError("URL invalide")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]] else {
            throw CROUSError.parseError
        }
        return results.compactMap { dict -> CrousRegion? in
            guard let urlStr = dict["url"] as? String,
                  let rawName = dict["name"] as? String else { return nil }
            // JS : url.split("/")[4] inclut les segments vides dus à "//".
            // Swift : split(separator:) les ignore, donc l'index est décalé.
            // On cherche le segment qui suit "feed" via URL.pathComponents.
            guard let parsed = URL(string: urlStr) else { return nil }
            let comps = parsed.pathComponents   // ex: ["/", "feed", "aix-marseille"]
            guard let feedIdx = comps.firstIndex(of: "feed"),
                  feedIdx + 1 < comps.count else { return nil }
            let identifier = comps[feedIdx + 1]
            guard !identifier.isEmpty else { return nil }
            let name = rawName.replacingOccurrences(of: "FLUX ", with: "")
            return CrousRegion(id: identifier, name: name)
        }
    }

    // MARK: - Restaurants d'une région

    static func fetchRestaurants(for identifier: String) async throws -> [CrousRestaurant] {
        let urlStr = baseURL + "\(identifier)/externe/crous-\(identifier).min.json"
        guard let url = URL(string: urlStr) else {
            throw CROUSError.networkError("URL invalide")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        var text = String(data: data, encoding: .utf8) ?? ""
        // Suppression des caractères de contrôle (comme dans Crowous.js)
        text = text.replacingOccurrences(of: "[\\x00-\\x1F]", with: "", options: .regularExpression)

        guard let cleanData = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: cleanData) as? [String: Any],
              let list = json["restaurants"] as? [[String: Any]] else {
            throw CROUSError.parseError
        }

        return list.compactMap { dict -> CrousRestaurant? in
            guard let id = dict["id"] as? Int,
                  let title = dict["title"] as? String else { return nil }
            return CrousRestaurant(
                id: id,
                title: title,
                address: dict["adresse"] as? String ?? "",
                shortDescription: dict["shortdesc"] as? String ?? "",
                latitude: dict["lat"] as? Double,
                longitude: dict["lon"] as? Double,
                opening: dict["opening"] as? String ?? ""
            )
        }
    }

    // MARK: - Tous les menus d'un restaurant (triés par date)

    static func fetchAllMenus(
        for identifier: String,
        restaurantId: Int
    ) async throws -> [CrousMenu] {
        let urlStr = baseURL + "\(identifier)/externe/menu2014.xml"
        guard let url = URL(string: urlStr) else {
            throw CROUSError.networkError("URL invalide")
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        let parser = CROUSMenuXMLParser()
        return parser.parse(data: data, restaurantId: restaurantId)
            .sorted { $0.date < $1.date }
    }
}

// MARK: - Parser XML des menus Crous

// MARK: - Parser XML des menus Crous
// Format réel observé :
//   <plat><nom><![CDATA[Nom du plat]]></nom></plat>
// → le nom du plat est un élément <nom> enfant de <plat>, pas un attribut.

private class CROUSMenuXMLParser: NSObject, XMLParserDelegate {
    private var menus: [CrousMenu] = []
    private var targetRestaurantTag: String = ""

    private var inTargetMenu    = false
    private var inPlat          = false
    private var inPlatNom       = false
    private var currentDate:         Date?
    private var currentMeals:        [CrousMeal] = []
    private var currentMoment:       String?
    private var currentCategories:   [CrousFoodCategory] = []
    private var currentCategoryName: String?
    private var currentDishes:       [String] = []
    private var currentDishBuffer:   String = ""
    private var currentInformation:  String?

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "fr_FR")
        return f
    }()

    func parse(data: Data, restaurantId: Int) -> [CrousMenu] {
        self.targetRestaurantTag = "r\(restaurantId)"
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return menus
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        switch elementName {
        case "menu":
            let restaurant = attributeDict["restaurant"] ?? ""
            if restaurant == targetRestaurantTag {
                inTargetMenu = true
                currentDate  = Self.dateFormatter.date(from: attributeDict["date"] ?? "")
                currentMeals = []
            } else {
                inTargetMenu = false
            }

        case "repas" where inTargetMenu:
            currentMoment     = attributeDict["nom"]
            currentCategories = []
            currentInformation = nil

        case "plats" where inTargetMenu:
            // Le nom de catégorie est bien un attribut : <plats nom="ENTREES">
            currentCategoryName = attributeDict["nom"]
            currentDishes       = []

        case "plat" where inTargetMenu:
            inPlat          = true
            currentDishBuffer = ""

        case "nom" where inTargetMenu && inPlat:
            // <plat><nom><![CDATA[...]]></nom></plat>
            inPlatNom       = true
            currentDishBuffer = ""

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inPlatNom else { return }
        currentDishBuffer += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard inPlatNom,
              let text = String(data: CDATABlock, encoding: .utf8) else { return }
        currentDishBuffer += text
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        switch elementName {
        case "nom" where inTargetMenu && inPlat:
            inPlatNom = false
            let trimmed = currentDishBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                currentDishes.append(trimmed)
            }
            currentDishBuffer = ""

        case "plat" where inTargetMenu:
            inPlat    = false
            inPlatNom = false

        case "menu":
            guard inTargetMenu, let date = currentDate else {
                inTargetMenu = false
                return
            }
            menus.append(CrousMenu(date: date, meals: currentMeals))
            inTargetMenu = false

        case "repas" where inTargetMenu:
            guard let moment = currentMoment else { return }
            let filtered = currentCategories.filter {
                let lower = $0.name.lowercased()
                return lower != "informations" && lower != "fermeture"
            }
            currentMeals.append(CrousMeal(
                moment: moment,
                categories: filtered,
                information: currentInformation
            ))
            currentMoment = nil

        case "plats" where inTargetMenu:
            guard let name = currentCategoryName else { return }
            let lower = name.lowercased()
            if lower == "informations" || lower == "fermeture" {
                currentInformation = currentDishes.first
            } else {
                currentCategories.append(CrousFoodCategory(name: name, dishes: currentDishes))
            }
            currentCategoryName = nil

        default:
            break
        }
    }
}
