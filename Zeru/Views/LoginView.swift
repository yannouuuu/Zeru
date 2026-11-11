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
    @State private var focusedField: Field?

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

                SecondaryCapsuleButton(title: "Découvrir la démo", systemImage: "sparkles") {
                    authVM.enterDemoMode()
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)

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
                returnKeyType: .next,
                usesEmailKeyboard: true,
                onReturn: { focusedField = .password }
            )

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.leading, 48)

            field(
                icon: "lock",
                placeholder: "Mot de passe",
                text: $password,
                isSecure: !isPasswordVisible,
                focus: .password,
                returnKeyType: .go,
                onReturn: submit,
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
        returnKeyType: UIReturnKeyType,
        usesEmailKeyboard: Bool = false,
        onReturn: @escaping () -> Void,
        trailing: AnyView? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 20)

            LoginTextInput(
                text: text,
                placeholder: placeholder,
                isSecure: isSecure,
                isFocused: focusBinding(for: focus),
                keyboardType: usesEmailKeyboard ? .emailAddress : .default,
                returnKeyType: returnKeyType,
                onReturn: onReturn
            )
            .frame(height: 22)

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

    private func focusBinding(for field: Field) -> Binding<Bool> {
        Binding(
            get: { focusedField == field },
            set: { isFocused in
                focusedField = isFocused ? field : (focusedField == field ? nil : focusedField)
            }
        )
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

private struct LoginTextInput: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let isSecure: Bool
    @Binding var isFocused: Bool
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType
    let onReturn: () -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)

        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.textColor = .white
        textField.tintColor = .white
        textField.font = Self.font
        textField.attributedPlaceholder = Self.placeholder(placeholder)

        textField.keyboardAppearance = .dark
        textField.keyboardType = keyboardType
        textField.returnKeyType = returnKeyType
        textField.enablesReturnKeyAutomatically = false
        textField.isSecureTextEntry = isSecure

        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.spellCheckingType = .no
        textField.smartDashesType = .no
        textField.smartQuotesType = .no
        textField.smartInsertDeleteType = .no
        textField.textContentType = nil
        textField.passwordRules = nil

        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        context.coordinator.parent = self

        if textField.text != text {
            textField.text = text
        }

        if textField.placeholder != placeholder {
            textField.attributedPlaceholder = Self.placeholder(placeholder)
        }

        if textField.isSecureTextEntry != isSecure {
            textField.isSecureTextEntry = isSecure
        }

        if textField.keyboardType != keyboardType {
            textField.keyboardType = keyboardType
        }

        if textField.returnKeyType != returnKeyType {
            textField.returnKeyType = returnKeyType
        }

        if isFocused, !textField.isFirstResponder {
            textField.becomeFirstResponder()
        } else if !isFocused, textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private static var font: UIFont {
        UIFont(name: "Geist-Regular", size: 15) ?? .systemFont(ofSize: 15)
    }

    private static func placeholder(_ value: String) -> NSAttributedString {
        NSAttributedString(
            string: value,
            attributes: [
                .foregroundColor: UIColor.white.withAlphaComponent(0.35),
                .font: font
            ]
        )
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: LoginTextInput

        init(parent: LoginTextInput) {
            self.parent = parent
        }

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onReturn()
            return false
        }
    }
}
