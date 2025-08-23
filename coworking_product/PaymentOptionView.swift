//
//  PaymentOptionView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct PaymentOptionView: View {
    let label: String
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .frame(width: 24)
                Text(label)
                    .fontWeight(.medium)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(isSelected ? Color.gray.opacity(0.2) : Color.gray.opacity(0.07))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
