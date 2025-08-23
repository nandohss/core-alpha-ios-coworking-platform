//
//  InviteView.swift
//  coworking_product
//
//  Created by Fernando on 05/07/25.
//

import SwiftUI

struct InviteView: View {
    var body: some View {
        VStack {
            Text("Convide amigos e ganhe vantagens ao indicar a plataforma!")
                .padding()
                .multilineTextAlignment(.center)
        }
        .navigationTitle("Indicações")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#Preview {
    InviteView()
}
