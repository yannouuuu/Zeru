//
//  ActivationView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import UIKit

struct ActivationView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var activationURL = ""
    @State private var clipboardURLCandidate: String? = nil
    @Namespace private var namespace
    @Environment(\.scenePhase) private var scenePhase

    private var normalizedActivationURL: String { activationURL.trimmed }

    private var shouldShowClipboardSuggestion: Bool {
        guard let candidate = clipboardURLCandidate else { return false }
        return candidate != normalizedActivationURL
    }

    private func refreshClipboardCandidate() {
        guard let raw = UIPasteboard.general.string?.trimmed.nilIfBlank else {
            clipboardURLCandidate = nil
            return
        }

        let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            clipboardURLCandidate = nil
            return
        }

        let matches = detector.matches(in: raw, options: [], range: range)
        let candidate = matches
            .compactMap(\ .url)
            .map(\ .absoluteString)
            .first { $0.localizedCaseInsensitiveContains("izly") }

        if let candidate {
            clipboardURLCandidate = candidate
            return
        }

        // Fallback: le presse-papiers peut contenir directement une URL sans texte autour.
        if raw.localizedCaseInsensitiveContains("izly"),
           let url = URL(string: raw),
           let scheme = url.scheme?.lowercased(),
           scheme == "https" || scheme == "http" {
            clipboardURLCandidate = url.absoluteString
        } else {
            clipboardURLCandidate = nil
        }
    }

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

                    if shouldShowClipboardSuggestion,
                       let candidate = clipboardURLCandidate {
                        Button {
                            activationURL = candidate
                        } label: {
                            Label("Utiliser le lien copie", systemImage: "doc.on.clipboard")
                                .font(.footnote.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.glass)
                    }

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
        .onAppear {
            refreshClipboardCandidate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshClipboardCandidate()
            }
        }
    }
}
