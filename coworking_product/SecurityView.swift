//
//  SecurityView.swift
//  coworking_product
//
//  Created by Fernando on 05/07/25.
//

import SwiftUI

struct SecurityView: View {
    var body: some View {
        VStack {
            Text("Gerencie suas configurações de segurança e privacidade aqui.")
                .padding()
                .multilineTextAlignment(.center)
        }
        .navigationTitle("Segurança")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    SecurityView()
}
