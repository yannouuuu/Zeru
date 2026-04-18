//
//  ActivationView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct ActivationView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var activationURL = ""
    @Namespace private var namespace

    private var normalizedActivationURL: String { activationURL.trimmed }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Icône + texte ──────────────────────────
                VStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 52, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .glassEffect(.regular, in: .circle)
                        .frame(width: 90, height: 90)

                    Text("Vérifie tes messages")
                        .font(.title2.bold())

                    Text("Izly t'a envoyé un lien par SMS ou email.\nColle-le ci-dessous.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // ── Champ + boutons en bas ─────────────────
                VStack(spacing: 12) {

                    GlassEffectContainer(spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)
                            TextField("https://mon-espace.izly.fr/...", text: $activationURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .foregroundStyle(activationURL.isEmpty ? .secondary : .primary)
                                .opacity(activationURL.isEmpty ? 0.6 : 1)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    if let error = authVM.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                        .transition(.opacity)
                    }

                    Button {
                        Task { await authVM.tokenize(activationURL: normalizedActivationURL) }
                    } label: {
                        Group {
                            if authVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Activer")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(authVM.isLoading || normalizedActivationURL.isEmpty)

                    Button {
                        authVM.step = .login
                    } label: {
                        Text("Retour")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.glass)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .animation(.spring(duration: 0.3), value: authVM.errorMessage)
    }
}
