//
//  NotificationService.swift
//  Zeru
//
//  Created by Yann Renard on 15/03/2026.
//

import Foundation
import UserNotifications

// MARK: - Service de notifications locales

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // Clé UserDefaults pour les IDs déjà vus (évite de notifier les anciennes transactions)
    private let seenIDsKey = "notif.seenTransactionIDs"
    private let lastLowBalanceDateKey = "notif.lastLowBalanceDate"

    // MARK: - Permission

    func requestAuthorizationIfNeeded() async {
        let status = await authorizationStatus()
        guard status == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    // MARK: - Traitement des nouvelles transactions

    /// Appeler après chaque sync Izly.
    /// - `isInitialLoad`: si true, enregistre les transactions comme "vues" sans notifier.
    func processNewTransactions(
        _ transactions: [IzlyTransaction],
        balance: Double,
        isInitialLoad: Bool = false
    ) async {
        let status = await authorizationStatus()
        guard status == .authorized else { return }

        let seenIDs = Set(UserDefaults.standard.stringArray(forKey: seenIDsKey) ?? [])
        let newTransactions = transactions.filter { !seenIDs.contains($0.id) }

        // Met à jour les IDs vus avant d'envoyer des notifs
        let updatedIDs = seenIDs.union(transactions.map { $0.id })
        UserDefaults.standard.set(Array(updatedIDs), forKey: seenIDsKey)

        guard !isInitialLoad else { return }

        for tx in newTransactions {
            sendTransactionNotification(for: tx)
        }

        checkLowBalance(balance)
    }

    // MARK: - Notifs individuelles

    private func sendTransactionNotification(for tx: IzlyTransaction) {
        // Lecture des préférences directement en UserDefaults (indépendant de SwiftUI)
        switch tx.group {
        case 0: // Rechargements
            guard UserDefaults.standard.object(forKey: "notif.recharges") as? Bool ?? true else { return }
            schedule(
                id: "tx-\(tx.id)",
                title: "Rechargement reçu",
                body: "+\(tx.amount.euroFormatted) ajouté sur ton compte Izly"
            )
        case 1: // Virements
            guard UserDefaults.standard.object(forKey: "notif.transfers") as? Bool ?? true else { return }
            schedule(
                id: "tx-\(tx.id)",
                title: "Virement",
                body: "\(tx.amount.signedEuroFormatted) — \(tx.label)"
            )
        case 2: // Paiements
            guard UserDefaults.standard.object(forKey: "notif.payments") as? Bool ?? true else { return }
            schedule(
                id: "tx-\(tx.id)",
                title: "Paiement effectué",
                body: "\(abs(tx.amount).euroFormatted) — \(tx.label)"
            )
        default:
            break
        }
    }

    private func checkLowBalance(_ balance: Double) {
        guard UserDefaults.standard.object(forKey: "notif.lowBalance") as? Bool ?? true else { return }
        let threshold = UserDefaults.standard.object(forKey: "notif.lowBalanceThreshold") as? Double ?? 2.0
        guard balance < threshold else { return }

        // Maximum une alerte par jour pour éviter le spam
        if let lastDate = UserDefaults.standard.object(forKey: lastLowBalanceDateKey) as? Date,
           Calendar.current.isDateInToday(lastDate) { return }

        schedule(
            id: "low-balance",
            title: "Solde Izly bas",
            body: "Il te reste \(balance.rounded2.euroFormatted) — pense à recharger !"
        )
        UserDefaults.standard.set(Date(), forKey: lastLowBalanceDateKey)
    }

    // MARK: - Envoi UNNotification

    private func schedule(id: String, title: String, body: String) {
        let content       = UNMutableNotificationContent()
        content.title     = title
        content.body      = body
        content.sound     = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}
