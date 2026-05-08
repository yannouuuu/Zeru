//
//  AppFont.swift
//  Zeru
//
//  Provider de polices custom (Geist) inspiré de Remodex.
//  Charge automatiquement Geist-Regular/Medium/SemiBold/Bold via UIAppFonts.
//

import SwiftUI
import UIKit

enum AppFont {

    private static func faceName(for weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy, .bold:
            return "Geist-Bold"
        case .semibold:
            return "Geist-SemiBold"
        case .medium:
            return "Geist-Medium"
        default:
            return "Geist-Regular"
        }
    }

    private static func custom(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle) -> Font {
        let name = faceName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(style, weight: weight)
    }

    private static func customFixed(size: CGFloat, weight: Font.Weight) -> Font {
        let name = faceName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: weight)
    }

    static func body(weight: Font.Weight = .regular) -> Font {
        custom(size: 15, weight: weight, relativeTo: .body)
    }

    static func callout(weight: Font.Weight = .regular) -> Font {
        custom(size: 14.5, weight: weight, relativeTo: .callout)
    }

    static func subheadline(weight: Font.Weight = .regular) -> Font {
        custom(size: 14, weight: weight, relativeTo: .subheadline)
    }

    static func footnote(weight: Font.Weight = .regular) -> Font {
        custom(size: 12, weight: weight, relativeTo: .footnote)
    }

    static func caption(weight: Font.Weight = .regular) -> Font {
        custom(size: 11, weight: weight, relativeTo: .caption)
    }

    static func caption2(weight: Font.Weight = .regular) -> Font {
        custom(size: 10, weight: weight, relativeTo: .caption2)
    }

    static func headline(weight: Font.Weight = .bold) -> Font {
        custom(size: 15.5, weight: weight, relativeTo: .headline)
    }

    static func title3(weight: Font.Weight = .medium) -> Font {
        custom(size: 18, weight: weight, relativeTo: .title3)
    }

    static func title2(weight: Font.Weight = .bold) -> Font {
        custom(size: 20, weight: weight, relativeTo: .title2)
    }

    static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        customFixed(size: size, weight: weight)
    }
}
