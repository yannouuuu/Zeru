//
//  AppearancePickerView.swift
//  Zeru
//
//  Created by Yann Renard on 14/03/2026.
//


import SwiftUI

struct AppearancePickerView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        let current = settings

        List {
            ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                Button {
                    current.appearanceMode = mode
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: mode.icon)
                            .frame(width: 24)
                            .foregroundStyle(.tint)

                        Text(mode.label)
                            .foregroundStyle(.primary)

                        Spacer()

                        if current.appearanceMode == mode {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .navigationTitle("Thème")
        .navigationBarTitleDisplayMode(.inline)
    }
}
