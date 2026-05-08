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
    @FocusState private var isURLFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    private var normalizedActivationURL: String { activationURL.trimmed }

    private var shouldShowClipboardSuggestion: Bool {
        guard let candidate = clipboardURLCandidate else { return false }
        return candidate != normalizedActivationURL
    }

    private var accentGradient: LinearGradient {
        LinearGradient(
            colors: [Color.accentColor.opacity(0.35), Color.accentColor.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
            .compactMap(\.url)
            .map(\.absoluteString)
            .first { $0.localizedCaseInsensitiveContains("izly") }

        if let candidate {
            clipboardURLCandidate = candidate
            return
        }

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
            Color.black.ignoresSafeArea()

            ambientBackground

            VStack(spacing: 0) {
                Spacer()

                hero

                Spacer()

                form
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(duration: 0.3), value: authVM.errorMessage)
        .animation(.spring(duration: 0.3), value: shouldShowClipboardSuggestion)
        .onAppear { refreshClipboardCandidate() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshClipboardCandidate()
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 36) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.18), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "envelope.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(accentGradient, lineWidth: 1)
                    )
            }

            VStack(spacing: 12) {
                Text("Vérifie tes messages")
                    .font(AppFont.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Izly t'a envoyé un lien par SMS ou email.\nColle-le ci-dessous pour activer ton accès.")
                    .font(AppFont.subheadline(weight: .regular))
                    .foregroundStyle(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Form

    private var form: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "link")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 20)

                TextField("",
                          text: $activationURL,
                          prompt: Text("https://mon-espace.izly.fr/...")
                            .font(AppFont.body())
                            .foregroundStyle(.white.opacity(0.35)))
                    .font(AppFont.body())
                    .foregroundStyle(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($isURLFocused)
                    .submitLabel(.go)
                    .onSubmit { submit() }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            if shouldShowClipboardSuggestion, let candidate = clipboardURLCandidate {
                Button {
                    activationURL = candidate
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Utiliser le lien copié")
                            .font(AppFont.footnote(weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                    )
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let error = authVM.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(AppFont.caption(weight: .semibold))
                    Text(error)
                        .font(AppFont.caption(weight: .medium))
                }
                .foregroundStyle(Color.red.opacity(0.85))
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            PrimaryCapsuleButton(
                title: "Activer",
                isLoading: authVM.isLoading,
                isEnabled: !authVM.isLoading && !normalizedActivationURL.isEmpty
            ) {
                submit()
            }
            .padding(.top, 4)

            SecondaryCapsuleButton(title: "Retour") {
                authVM.step = .login
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    // MARK: - Background

    private var ambientBackground: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.18))
                    .frame(width: geo.size.width * 0.85)
                    .blur(radius: 70)
                    .offset(x: -geo.size.width * 0.25, y: -geo.size.height * 0.3)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Actions

    private func submit() {
        guard !normalizedActivationURL.isEmpty else { return }
        isURLFocused = false
        Task { await authVM.tokenize(activationURL: normalizedActivationURL) }
    }
}
