//
//  PrimaryCapsuleButton.swift
//  Zeru
//
//  CTA principal style Remodex: capsule blanche, texte noir, hauteur 56.
//

import SwiftUI

struct PrimaryCapsuleButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.black)
                } else {
                    if let systemImage, !systemImage.isEmpty {
                        Image(systemName: systemImage)
                            .font(.system(size: 15, weight: .semibold))
                    }

                    Text(title)
                        .font(AppFont.body(weight: .semibold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white, in: Capsule())
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 12) {
            PrimaryCapsuleButton(title: "Se connecter") {}
            PrimaryCapsuleButton(title: "Scanner", systemImage: "qrcode") {}
            PrimaryCapsuleButton(title: "Chargement", isLoading: true) {}
            PrimaryCapsuleButton(title: "Désactivé", isEnabled: false) {}
        }
        .padding(24)
    }
    .preferredColorScheme(.dark)
}
