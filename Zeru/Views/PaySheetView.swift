//
//  PaySheetView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI

struct PaySheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var payVM = PayViewModel()
    @Binding var isPresented: Bool
    @Namespace private var namespace

    private let haptic = UINotificationFeedbackGenerator()

    var body: some View {
        ZStack {
            // ── Fond adaptatif ─────────────────────────
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()

            VStack(spacing: 32) {

                // ── Header ─────────────────────────────
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payer")
                            .font(.largeTitle.bold())
                        Text("Fais scanner ce QR code")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        payVM.stopTimer()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .frame(width: 32, height: 32)
                            .glassEffect(.regular, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                // ── QR Code ────────────────────────────
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.white)
                        .frame(width: 260, height: 260)
                        .shadow(color: .black.opacity(0.08), radius: 20)

                    if let image = payVM.qrImage {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 220, height: 220)
                            .opacity(payVM.isExpired ? 0.15 : 1)
                            .animation(.easeOut(duration: 0.3), value: payVM.isExpired)
                    }

                    if payVM.isExpired {
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Rafraîchissement...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.spring(duration: 0.4), value: payVM.qrImage != nil)

                // ── Compte à rebours ───────────────────
                GlassEffectContainer(spacing: 0) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                                .frame(width: 56, height: 56)

                            Circle()
                                .trim(from: 0, to: CGFloat(payVM.timeLeft) / 30)
                                .stroke(
                                    timerColor,
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 56, height: 56)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: payVM.timeLeft)

                            Text("\(payVM.timeLeft)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(timerColor)
                                .animation(.none, value: payVM.timeLeft)
                        }

                        Text("secondes restantes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 28)

                // ── Infos utilisateur ──────────────────
                if let profile = authVM.profile {
                    HStack(spacing: 10) {
                        Text(initials)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .glassEffect(.regular, in: .circle)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(profile.firstName) \(profile.lastName)")
                                .font(.subheadline.bold())
                            Text(authVM.balance.euroFormatted)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        Text("Izly")
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .padding(.horizontal, 28)
                }

                Spacer()
            }
        }
        .onAppear {
            haptic.prepare()
            if let identification = authVM.identification {
                payVM.setup(
                    identification: identification,
                    seed: identification.seed
                )
            }
        }
        .onChange(of: payVM.counter) { _, _ in
            haptic.notificationOccurred(.success)
        }
    }

    private var timerColor: Color {
        switch payVM.timeLeft {
        case 11...30: return .green
        case 6...10:  return .orange
        default:      return .red
        }
    }

    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? ""
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }
}
