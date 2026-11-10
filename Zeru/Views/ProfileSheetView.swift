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
            List {
                Section {
                    header
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20))
                }

                Section("Compte") {
                    LabeledContent {
                        Text(authVM.balance.euroFormatted)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    } label: {
                        Label("Solde", systemImage: "creditcard")
                    }

                    LabeledContent {
                        Text(authVM.profile?.identifier ?? "")
                            .lineLimit(1)
                    } label: {
                        Label("Identifiant", systemImage: "person.text.rectangle")
                    }
                }

                Section("Statistiques") {
                    LabeledContent {
                        Text("\(mealCount)")
                            .monospacedDigit()
                    } label: {
                        Label("Repas pris", systemImage: "fork.knife")
                    }

                    LabeledContent {
                        Text(totalSpent.euroFormatted)
                            .monospacedDigit()
                    } label: {
                        Label("Total dépensé", systemImage: "eurosign.circle")
                    }

                    LabeledContent {
                        Text(averagePerMeal.euroFormatted)
                            .monospacedDigit()
                    } label: {
                        Label("Moyenne par repas", systemImage: "chart.line.uptrend.xyaxis")
                    }

                    LabeledContent {
                        Text(totalTopup.euroFormatted)
                            .monospacedDigit()
                    } label: {
                        Label("Rechargements", systemImage: "arrow.down.circle")
                    }
                }
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
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
                    .lineLimit(1)
            }
        }
    }
}
