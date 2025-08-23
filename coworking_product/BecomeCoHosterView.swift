//
//  BecomeCoHousterView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct BecomeCoHosterView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "house.and.flag.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.black)
                
                Text("Anuncie seu espaço")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Transforme seu local em uma fonte de renda ao disponibilizá-lo como espaço compartilhado.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                Button(action: {
                    // Aqui você pode navegar para um formulário de cadastro de espaço
                    print("Tornar-se CoHoster")
                }) {
                    Text("Tornar-se CoHoster")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Seja um CoHoster")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    BecomeCoHosterView()
}
