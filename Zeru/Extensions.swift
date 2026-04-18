//
//  Extensions.swift
//  Zeru
//
//  Created by Yann Renard on 18/04/2026.
//

import Foundation

extension Double {
    /// Format monetaire FR en euros (ex: 12,34 €)
    var euroFormatted: String {
        let fmt          = NumberFormatter()
        fmt.numberStyle  = .currency
        fmt.currencyCode = "EUR"
        fmt.locale       = Locale(identifier: "fr_FR")
        return fmt.string(from: NSNumber(value: self)) ?? "\(self) €"
    }

    /// Ajoute explicitement un "+" pour les montants positifs.
    var signedEuroFormatted: String {
        self >= 0 ? "+\(euroFormatted)" : euroFormatted
    }

    /// Arrondi a 2 decimales pour affichage/calculs UI.
    var rounded2: Double {
        (self * 100).rounded() / 100
    }
}

extension Int {
    var euroFormatted: String {
        Double(self).euroFormatted
    }
}

extension Date {
    /// Exemple: "18 avr. 2026"
    var shortFrenchDate: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: self)
    }

    /// Exemple: "18/04"
    var dayMonthFrench: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "dd/MM"
        return fmt.string(from: self)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
