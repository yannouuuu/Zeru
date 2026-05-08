//
//  SecondaryCapsuleButton.swift
//  Zeru
//
//  CTA secondaire style Remodex: capsule transparente bordée blanc 18%.
//

import SwiftUI

struct SecondaryCapsuleButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage, !systemImage.isEmpty {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
                    .font(AppFont.body(weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            SecondaryCapsuleButton(title: "Retour") {}
            SecondaryCapsuleButton(title: "Coller", systemImage: "doc.on.clipboard") {}
        }
        .padding(24)
    }
    .preferredColorScheme(.dark)
}
