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

    static let balance: Double = 24.50

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

    private static func timestamp(daysAgo: Int, hour: Int, minute: Int) -> Double {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let composed = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        return composed.timeIntervalSince1970 * 1000
    }

    static let transactions: [IzlyTransaction] = [
        // Aujourd'hui
        IzlyTransaction(id: "demo-1", date: "Aujourd'hui", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 0, hour: 12, minute: 34)),
        IzlyTransaction(id: "demo-2", date: "Aujourd'hui", label: "Cafétéria — Crous Jussieu", amount: -1.10, group: 0, timestamp: timestamp(daysAgo: 0, hour: 9, minute: 12)),
        // Cette semaine
        IzlyTransaction(id: "demo-3", date: "Hier", label: "Resto U — Crous Mabillon", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 1, hour: 12, minute: 21)),
        IzlyTransaction(id: "demo-4", date: "Hier", label: "Rechargement par carte", amount: 20.00, group: 1, timestamp: timestamp(daysAgo: 2, hour: 18, minute: 45)),
        IzlyTransaction(id: "demo-5", date: "Lundi", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 4, hour: 12, minute: 40)),
        IzlyTransaction(id: "demo-6", date: "Lundi", label: "Virement reçu", amount: 10.00, group: 2, timestamp: timestamp(daysAgo: 4, hour: 20, minute: 3)),
        IzlyTransaction(id: "demo-7", date: "Vendredi", label: "Boulangerie du campus", amount: -2.40, group: 0, timestamp: timestamp(daysAgo: 6, hour: 8, minute: 27)),
        // Ce mois-ci
        IzlyTransaction(id: "demo-8", date: "Jeudi", label: "Resto U — Crous Censier", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 9, hour: 12, minute: 15)),
        IzlyTransaction(id: "demo-9", date: "Lundi", label: "Cafétéria — Crous Jussieu", amount: -1.10, group: 0, timestamp: timestamp(daysAgo: 12, hour: 10, minute: 4)),
        IzlyTransaction(id: "demo-10", date: "Lundi", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 16, hour: 12, minute: 28)),
        IzlyTransaction(id: "demo-11", date: "Mercredi", label: "Rechargement par carte", amount: 30.00, group: 1, timestamp: timestamp(daysAgo: 21, hour: 19, minute: 2)),
        IzlyTransaction(id: "demo-12", date: "Vendredi", label: "Resto U — Crous Mabillon", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 26, hour: 12, minute: 9)),
        // Le mois dernier
        IzlyTransaction(id: "demo-13", date: "Octobre", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 34, hour: 12, minute: 33)),
        IzlyTransaction(id: "demo-14", date: "Octobre", label: "Rechargement par carte", amount: 20.00, group: 1, timestamp: timestamp(daysAgo: 45, hour: 17, minute: 51)),
        IzlyTransaction(id: "demo-15", date: "Septembre", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 58, hour: 12, minute: 22)),
        IzlyTransaction(id: "demo-16", date: "Septembre", label: "Virement reçu", amount: 15.00, group: 2, timestamp: timestamp(daysAgo: 75, hour: 21, minute: 10)),
        IzlyTransaction(id: "demo-17", date: "Août", label: "Resto U — Crous Censier", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 96, hour: 12, minute: 5)),
        IzlyTransaction(id: "demo-18", date: "Juillet", label: "Rechargement par carte", amount: 50.00, group: 1, timestamp: timestamp(daysAgo: 120, hour: 18, minute: 30)),
        IzlyTransaction(id: "demo-19", date: "Juin", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 150, hour: 12, minute: 18)),
        IzlyTransaction(id: "demo-20", date: "Mai", label: "Resto U — Crous Mabillon", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 180, hour: 12, minute: 44)),
        IzlyTransaction(id: "demo-21", date: "Mars", label: "Rechargement par carte", amount: 30.00, group: 1, timestamp: timestamp(daysAgo: 240, hour: 19, minute: 15)),
        IzlyTransaction(id: "demo-22", date: "Janvier", label: "Resto U — Crous Jussieu", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 300, hour: 12, minute: 30)),
        IzlyTransaction(id: "demo-23", date: "Décembre", label: "Resto U — Crous Censier", amount: -3.30, group: 0, timestamp: timestamp(daysAgo: 340, hour: 12, minute: 12))
    ]

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
