//
//  LoginView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import UIKit

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    private enum Field { case username, password }

    private var normalizedUsername: String { username.trimmed }
    private var normalizedPassword: String { password.trimmed }
    private var isValid: Bool { !normalizedUsername.isEmpty && !normalizedPassword.isEmpty }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                hero
                    .padding(.bottom, 40)

                formCard

                if let error = authVM.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(AppFont.caption(weight: .semibold))
                        Text(error)
                            .font(AppFont.caption(weight: .medium))
                    }
                    .foregroundStyle(Color.red.opacity(0.85))
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                PrimaryCapsuleButton(
                    title: "Se connecter",
                    isLoading: authVM.isLoading,
                    isEnabled: isValid && !authVM.isLoading
                ) {
                    submit()
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)

                Spacer()

                footer
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(duration: 0.3), value: authVM.errorMessage)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 24) {
            Image("IconPreviewClassic")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.25), .white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )

            VStack(spacing: 8) {
                Text("Zeru")
                    .font(AppFont.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Ton compte Izly, sans prise de tête.")
                    .font(AppFont.subheadline(weight: .regular))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 11, weight: .medium))
                Text("Identifiants protégés par le Keychain")
                    .font(AppFont.caption(weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.5))
        }
    }

    // MARK: - Form

    private var formCard: some View {
        VStack(spacing: 0) {
            field(
                icon: "envelope",
                placeholder: "Email ou numéro",
                text: $username,
                isSecure: false,
                focus: .username,
                submitLabel: .next,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            .onSubmit { focusedField = .password }

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.leading, 48)

            field(
                icon: "lock",
                placeholder: "Mot de passe",
                text: $password,
                isSecure: !isPasswordVisible,
                focus: .password,
                submitLabel: .go,
                keyboardType: .default,
                textContentType: nil,
                trailing: AnyView(
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                )
            )
            .onSubmit { submit() }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func field(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool,
        focus: Field,
        submitLabel: SubmitLabel,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        trailing: AnyView? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField("", text: text, prompt: placeholderText(placeholder))
                        .textContentType(.password)
                } else {
                    TextField("", text: text, prompt: placeholderText(placeholder))
                        .textContentType(textContentType)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(AppFont.body())
            .foregroundStyle(.white)
            .tint(.white)
            .submitLabel(submitLabel)
            .focused($focusedField, equals: focus)

            if let trailing {
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func placeholderText(_ value: String) -> Text {
        Text(value)
            .font(AppFont.body())
            .foregroundStyle(.white.opacity(0.35))
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 4) {
            Text("En te connectant, tu acceptes les")
                .font(AppFont.caption2())
                .foregroundStyle(.white.opacity(0.3))
            Link("Conditions d'utilisation d'Izly",
                 destination: URL(string: "https://www.izly.fr/conditions-generales")!)
                .font(AppFont.caption2(weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 24)
    }

    // MARK: - Actions

    private func submit() {
        guard isValid else { return }
        focusedField = nil
        Task {
            await authVM.login(identifier: normalizedUsername, password: normalizedPassword)
        }
    }
}
