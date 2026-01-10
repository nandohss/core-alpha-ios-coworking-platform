
//
//  ReservationSuccessView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct ReservationSuccessView: View {
    enum Status { case pending, confirmed }
    
    var coworking: Coworking
    var selectedDate: Date
    var selectedHours: [Int]
    var paymentMethod: String
    var status: Status = .pending
    @Binding var selectedTab: Int

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Ícone conforme status
            Image(systemName: status == .confirmed ? "checkmark.seal.fill" : "clock.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(status == .confirmed ? .green : .orange)

            // Mensagem principal
            Text(status == .confirmed ? "Reserva confirmada!" : "Solicitação enviada!")
                .font(.title)
                .fontWeight(.bold)

            // Subtexto
            Group {
                if status == .confirmed {
                    Text("Sua reserva em \"\(coworking.nome)\" foi confirmada com sucesso.")
                } else {
                    Text("Sua solicitação de reserva em \"\(coworking.nome)\" foi realizada com sucesso e está aguardando aprovação do co-hoster.")
                }
            }
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
                if status == .confirmed {
                    detailRow("QR Code", "Gerado para apresentar no local")
                }
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
