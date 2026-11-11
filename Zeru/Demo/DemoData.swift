//
//  DemoData.swift
//  Zeru
//
//  Compte de démonstration : permet de découvrir l'app sans identifiants Izly.
//

import Foundation

enum DemoMode {
    private static let key = "zeru.demoMode"

    static var isActive: Bool {
        // `-demo` permet de lancer l'app directement en démonstration
        // (captures, démonstration sur appareil).
        ProcessInfo.processInfo.arguments.contains("-demo")
            || UserDefaults.standard.bool(forKey: key)
    }

    static func enable() {
        UserDefaults.standard.set(true, forKey: key)
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: key)
    }
}

enum DemoData {

    // MARK: - Profil

    static let profile = IzlyProfile(
        firstName: "Camille",
        lastName: "Moreau",
        email: "camille.moreau@etu.u-paris.fr",
        identifier: "camille.moreau@etu.u-paris.fr"
    )

    static let identification = IzlyIdentification(
        accessToken: "demo-access-token",
        refreshToken: "demo-refresh-token",
        sessionID: "demo-session",
        userID: "demo-user",
        identifier: "camille.moreau@etu.u-paris.fr",
        seed: "ZGVtby16ZXJ1LXNlZWQ=",
        counter: 0
    )

    // MARK: - Opérations

    // MARK: - Historique

    /// Historique cohérent : on simule l'année en partant d'un solde de 18 €,
    /// avec des repas au RU et des recharges quand le solde descend. Le solde
    /// final est celui affiché, et remonter le temps ne passe jamais sous zéro.
    private static let ledger: (balance: Double, transactions: [IzlyTransaction]) = generateLedger()

    static var balance: Double { ledger.balance }
    static var transactions: [IzlyTransaction] { ledger.transactions }

    private static func generateLedger() -> (balance: Double, transactions: [IzlyTransaction]) {
        let calendar = Calendar.current
        let now = Date()
        var balance = 18.0
        var generated: [IzlyTransaction] = []
        var identifier = 0

        for dayOffset in stride(from: 365, through: 0, by: -1) {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: day)
            let isWeekend = weekday == 1 || weekday == 7

            // Repas au RU en semaine, un jour sur deux.
            if !isWeekend && dayOffset % 2 == 0 {
                let isCafeteria = dayOffset % 10 == 0
                let amount = isCafeteria ? -1.10 : -3.30
                balance += amount
                identifier += 1
                generated.append(
                    IzlyTransaction(
                        id: "demo-\(identifier)",
                        date: shortDate(day),
                        label: isCafeteria ? "Cafétéria — Crous Jussieu" : "Resto U — Crous Jussieu",
                        amount: amount,
                        group: 0,
                        timestamp: timestamp(of: day, hour: isCafeteria ? 10 : 12, minute: isCafeteria ? 5 : 30)
                    )
                )
            }

            // Un virement reçu de temps en temps.
            if dayOffset % 90 == 15 {
                let amount = 10.0
                balance += amount
                identifier += 1
                generated.append(
                    IzlyTransaction(
                        id: "demo-\(identifier)",
                        date: shortDate(day),
                        label: "Virement reçu",
                        amount: amount,
                        group: 2,
                        timestamp: timestamp(of: day, hour: 20, minute: 10)
                    )
                )
            }

            // Recharge quand le solde descend, ou tous les 30 jours.
            if balance < 8 || dayOffset % 30 == 0 {
                let amount = 30.0
                balance += amount
                identifier += 1
                generated.append(
                    IzlyTransaction(
                        id: "demo-\(identifier)",
                        date: shortDate(day),
                        label: "Rechargement par carte",
                        amount: amount,
                        group: 1,
                        timestamp: timestamp(of: day, hour: 18, minute: 20)
                    )
                )
            }
        }

        return (balance, generated.reversed())
    }

    private static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: date)
    }

    private static func timestamp(of date: Date, hour: Int, minute: Int) -> Double {
        let calendar = Calendar.current
        let composed = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
        return composed.timeIntervalSince1970 * 1000
    }

    // MARK: - Crous

    static let regions: [CrousRegion] = [
        CrousRegion(id: "ile-de-france", name: "Île-de-France"),
        CrousRegion(id: "bordeaux", name: "Bordeaux"),
        CrousRegion(id: "lyon", name: "Lyon"),
        CrousRegion(id: "toulouse", name: "Toulouse"),
        CrousRegion(id: "lille", name: "Lille")
    ]

    static let restaurants: [CrousRestaurant] = [
        CrousRestaurant(
            id: 1,
            title: "Crous Jussieu",
            address: "4 place Jussieu, 75005 Paris",
            shortDescription: "Resto U du campus Jussieu",
            latitude: 48.8462,
            longitude: 2.3560,
            opening: "11h30 – 14h00"
        ),
        CrousRestaurant(
            id: 2,
            title: "Crous Mabillon",
            address: "3 rue Mabillon, 75006 Paris",
            shortDescription: "Self du quartier Latin",
            latitude: 48.8510,
            longitude: 2.3352,
            opening: "11h30 – 14h30"
        ),
        CrousRestaurant(
            id: 3,
            title: "Crous Censier",
            address: "13 rue Santeuil, 75005 Paris",
            shortDescription: "Cafétéria et self",
            latitude: 48.8405,
            longitude: 2.3505,
            opening: "08h00 – 15h00"
        )
    ]

    static let menus: [CrousMenu] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<5).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            return CrousMenu(date: date, meals: meals(for: offset))
        }
    }()

    private static func meals(for offset: Int) -> [CrousMeal] {
        let lunch = CrousMeal(
            moment: "midi",
            categories: [
                CrousFoodCategory(name: "Entrées", dishes: ["Carottes râpées au citron", "Œuf mimosa"]),
                CrousFoodCategory(name: "Plats", dishes: ["Poulet basquaise et riz complet", "Filet de poisson, sauce citron"]),
                CrousFoodCategory(name: "Fromages", dishes: ["Yaourt nature", "Fromage blanc"]),
                CrousFoodCategory(name: "Desserts", dishes: ["Tarte aux pommes", "Fruit de saison"])
            ],
            information: offset == 0 ? "Menu à 3,30 € — plat végétarien disponible." : nil
        )

        let dinner = CrousMeal(
            moment: "soir",
            categories: [
                CrousFoodCategory(name: "Plats", dishes: ["Gratin de courgettes", "Soupe de légumes"]),
                CrousFoodCategory(name: "Desserts", dishes: ["Compote maison"])
            ],
            information: nil
        )

        return offset >= 5 ? [] : [lunch, dinner]
    }
}
