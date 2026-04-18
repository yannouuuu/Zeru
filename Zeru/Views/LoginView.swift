//
//  LoginView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authVM: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @Namespace private var namespace

    private var normalizedUsername: String { username.trimmed }
    private var normalizedPassword: String { password.trimmed }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.background)
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Spacer()

                // ── Logo ──────────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 90, height: 90)
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .glassEffect(.regular, in: .circle)

                    Text("Zeru")
                        .font(.system(size: 42, weight: .bold, design: .rounded))

                    Text("Ton compte Izly, sans prise de tête")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 48)

                Spacer()

                // ── Formulaire ────────────────────────────
                GlassEffectContainer(spacing: 0) {
                    VStack(spacing: 0) {

                        HStack(spacing: 12) {
                            Image(systemName: "envelope")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)
                            TextField("Email ou numéro", text: $username)
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 0))
                        .glassEffectID("email", in: namespace)

                        Divider()
                            .padding(.leading, 48)

                        HStack(spacing: 12) {
                            Image(systemName: "lock")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)

                            if isPasswordVisible {
                                TextField("Mot de passe", text: $password)
                                    .textContentType(.password)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        Task {
                                            await authVM.login(identifier: normalizedUsername, password: normalizedPassword)
                                        }
                                    }
                            } else {
                                SecureField("Mot de passe", text: $password)
                                    .textContentType(.password)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        Task {
                                            await authVM.login(identifier: normalizedUsername, password: normalizedPassword)
                                        }
                                    }
                            }

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 0))
                        .glassEffectID("password", in: namespace)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 24)

                if let error = authVM.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // ── Bouton connexion ──────────────────────
                Button {
                    Task {
                        await authVM.login(identifier: normalizedUsername, password: normalizedPassword)
                    }
                } label: {
                    Group {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Se connecter")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.glassProminent)
                .disabled(authVM.isLoading || normalizedUsername.isEmpty || normalizedPassword.isEmpty)
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // ── Footer ────────────────────────────────
                VStack(spacing: 4) {
                    Text("En te connectant, tu acceptes les")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Link("Conditions d'utilisation d'Izly", destination: URL(string: "https://www.izly.fr/conditions-generales")!)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
            }
        }
        .animation(.spring(duration: 0.3), value: authVM.errorMessage)
    }
}
