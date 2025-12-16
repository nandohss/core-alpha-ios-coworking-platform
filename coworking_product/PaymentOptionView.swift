//
//  PaymentOptionView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct PaymentOptionView: View {
    var label: String
    var iconName: String
    var isSelected: Bool
    var onTap: () -> Void
    var isDisabled: Bool = false

    var body: some View {
        Button(action: {
            if !isDisabled {
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)

                Text(label)
                    .font(.subheadline)

                Spacer()

                if isSelected && !isDisabled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
    }

    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.1)
        } else {
            return isSelected ? Color.black : Color.gray.opacity(0.1)
        }
    }

    private var foregroundColor: Color {
        if isDisabled {
            return Color.gray
        } else {
            return isSelected ? Color.white : Color.black
        }
    }
}
