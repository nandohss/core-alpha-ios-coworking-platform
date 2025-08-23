//
//  FacilityView.swift
//  coworking_product
//
//  Created by Fernando on 05/07/25.
//

import SwiftUI

struct FacilityView: View {
    var facility: FacilityItem

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: facility.icon)
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            Text(facility.label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}
