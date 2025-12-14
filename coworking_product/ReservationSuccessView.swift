//
//  ReservationSuccessView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct ReservationSuccessView: View {
    var coworking: Coworking
    var selectedDate: Date
    var selectedHours: [Int]
    var paymentMethod: String
    @Binding var selectedTab: Int

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Ícone de sucesso
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)

            // Mensagem principal
            Text("Reserva Confirmada!")
                .font(.title)
                .fontWeight(.bold)

            // Subtexto
            Text("Sua reserva em \"\(coworking.nome)\" foi realizada com sucesso.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            // Detalhes da reserva
            VStack(alignment: .leading, spacing: 12) {
                detailRow("Espaço", coworking.nome)
                detailRow("Data", formattedDate)
                detailRow("Horários", selectedHours.map { "\($0)h" }.joined(separator: ", "))
                detailRow("Pagamento", paymentMethod)
                detailRow("QR Code", "Gerado para apresentar no local")
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)

            Spacer()

            // Botão para navegar para "Minhas Reservas"
            Button(action: {
                dismiss()
                selectedTab = 3
            }) {
                Text("Ver Minhas Reservas")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }

            Spacer(minLength: 40)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }

    func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: selectedDate)
    }
}

