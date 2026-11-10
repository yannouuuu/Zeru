//
//  ProfileSheetView.swift
//  Zeru
//
//  Profil : l'identité, le solde, trois chiffres. Rien de plus.
//

import SwiftUI
import PhotosUI

struct ProfileSheetView: View {
    @ObservedObject var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isPickerPresented = false

    // MARK: - Données

    private var totalSpent: Double {
        authVM.transactions.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
    }
    private var totalTopup: Double {
        authVM.transactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
    }
    private var mealCount: Int {
        authVM.transactions.filter { $0.amount < 0 }.count
    }
    private var initials: String {
        let f = authVM.profile?.firstName.prefix(1) ?? "?"
        let l = authVM.profile?.lastName.prefix(1) ?? ""
        return "\(f)\(l)".uppercased()
    }
    private var mealsRemaining: Int {
        max(0, Int(authVM.balance / 3.30))
    }

    // MARK: - Corps

    var body: some View {
        NavigationStack {
            List {
                Section {
                    hero
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 24, leading: 20, bottom: 20, trailing: 20))
                }

                Section {
                    LabeledContent("Repas pris") {
                        Text("\(mealCount)").monospacedDigit()
                    }
                    LabeledContent("Dépensé") {
                        Text(totalSpent.euroFormatted).monospacedDigit()
                    }
                    LabeledContent("Rechargé") {
                        Text(totalTopup.euroFormatted).monospacedDigit()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        authVM.logout()
                        dismiss()
                    } label: {
                        Text("Se déconnecter")
                            .frame(maxWidth: .infinity)
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
        .photosPicker(isPresented: $isPickerPresented, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    authVM.updateProfileImage(image)
                }
            }
        }
    }

    // MARK: - En-tête

    private var hero: some View {
        VStack(spacing: 16) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let image = authVM.profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 88, height: 88)
                                .clipShape(.circle)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.15))
                                    .frame(width: 88, height: 88)
                                Text(initials)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .glassEffect(.regular, in: .circle)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.accentColor, in: .circle)
                        .overlay(Circle().strokeBorder(.black.opacity(0.25), lineWidth: 1.5))
                        .offset(x: 2, y: 2)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Changer la photo de profil")

            VStack(spacing: 3) {
                Text("\(authVM.profile?.firstName ?? "") \(authVM.profile?.lastName ?? "")")
                    .font(.title2.weight(.bold))

                Text(authVM.profile?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            VStack(spacing: 4) {
                Text(authVM.balance.euroFormatted)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                Text("\(mealsRemaining) repas au RU")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 6)
        }
    }
}
