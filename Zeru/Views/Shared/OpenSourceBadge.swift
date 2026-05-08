//
//  OpenSourceBadge.swift
//  Zeru
//
//  Badge "Open source" cliquable, fidèle au style Remodex,
//  utilisé dans la bottom bar de l'onboarding.
//

import SwiftUI

struct OpenSourceBadge: View {
    enum BadgeStyle { case light, dark }

    var style: BadgeStyle = .light

    private let repoURL = URL(string: "https://github.com/yannouuuu/Zeru")!

    var body: some View {
        Link(destination: repoURL) {
            HStack(spacing: 6) {
                Image("GitHub")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 14, height: 14)

                Text("Open source")
                    .font(AppFont.caption(weight: .medium))
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(backgroundFill)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open source on GitHub")
    }

    private var foregroundColor: Color {
        switch style {
        case .light: .white.opacity(0.5)
        case .dark: .secondary
        }
    }

    private var backgroundFill: Color {
        switch style {
        case .light: .white.opacity(0.06)
        case .dark: Color(.tertiarySystemFill).opacity(0.5)
        }
    }

    private var borderColor: Color {
        switch style {
        case .light: .white.opacity(0.08)
        case .dark: Color.primary.opacity(0.06)
        }
    }
}

#Preview("Light (dark bg)") {
    ZStack {
        Color.black.ignoresSafeArea()
        OpenSourceBadge(style: .light)
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark (light bg)") {
    OpenSourceBadge(style: .dark)
        .padding()
}
