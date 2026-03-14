//
//  ProfileSheetView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//

import SwiftUI
import PhotosUI

struct ProfileSheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isPickerPresented = false

    private var totalSpent: Double {
        authVM.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }
    private var totalTopup: Double {
        authVM.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var mealCount: Int {
        authVM.transactions.filter { $0.amount < 0 }.count
    }
    private var averagePerMeal: Double {
        guard mealCount > 0 else { return 0 }
        return totalSpent / Double(mealCount)
    }
    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? "?"
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // ── Avatar cliquable ───────────────────────
                    VStack(spacing: 14) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let image = authVM.profileImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(.circle)
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color.accentColor.opacity(0.15))
                                                .frame(width: 100, height: 100)
                                            Text(initials)
                                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color.accentColor)
                                        }
                                    }
                                }
                                .glassEffect(.regular, in: .circle)

                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 4, y: 4)
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    authVM.updateProfileImage(image)
                                }
                            }
                        }

                        VStack(spacing: 4) {
                            Text("\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")")
                                .font(.title2.bold())
                            Text(authVM.profile?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(authVM.balance.euroFormatted)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)

                    // ── Infos compte ───────────────────────────
                    VStack(spacing: 0) {
                        InfoRow(icon: "person.text.rectangle", label: "Identifiant", value: authVM.profile?.email ?? "")
                        Divider().padding(.leading, 52)
                        InfoRow(icon: "number", label: "Alias", value: authVM.profile?.identifier ?? "")
                    }
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // ── Stats ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statistiques")
                            .font(.headline)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(icon: "fork.knife",             label: "Repas pris",     value: "\(mealCount)",                color: .orange)
                            StatCard(icon: "eurosign.circle",        label: "Total dépensé",  value: totalSpent.euroFormatted,      color: .red)
                            StatCard(icon: "chart.line.uptrend.xyaxis", label: "Moy. repas",  value: averagePerMeal.euroFormatted,  color: .blue)
                            StatCard(icon: "arrow.down.circle",      label: "Rechargements",  value: totalTopup.euroFormatted,      color: .green)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 16)
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .frame(width: 30, height: 30)
                            .glassEffect(.regular, in: .circle)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// ── Ligne d'info ───────────────────────────────────────
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)
                .padding(.leading, 16)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// ── Carte stat ─────────────────────────────────────────
struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}
