
// MARK: - Modelo de Detalhe da Reserva
struct DetalheReserva: Decodable {
    let reservaId: String
    let coworkingId: String
    let data: String
    let horarioInicio: String
    let horarioFim: String
    let status: String
}

// MARK: - ViewModel
class QRCodeReservaViewModel: ObservableObject {
    @Published var reserva: DetalheReserva? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func carregarDetalheReserva(id: String) async {
        guard let url = URL(string: "https://sua-api.amazonaws.com/prod/reserva/\(id)") else {
            self.errorMessage = "URL inválida"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(DetalheReserva.self, from: data)
            DispatchQueue.main.async {
                self.reserva = decoded
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Erro ao carregar detalhes da reserva: \(error.localizedDescription)"
            }
        }
    }
}


//
//  QRCodeDetailView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeDetailView: View {
    let reservation: Reservation

    var body: some View {
        VStack(spacing: 24) {
            Text("QR Code da Reserva")
                .font(.title2)
                .fontWeight(.semibold)

            if let qrImage = reservation.generateQRCodeImage() {
                Image(uiImage: qrImage)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 280)
                    .padding()
            } else {
                Text("Erro ao gerar QR Code.")
                    .foregroundColor(.red)
            }

            VStack(spacing: 6) {
                Text(reservation.coworkingName)
                    .font(.headline)
                Text("\(reservation.formattedDate), \(reservation.formattedHours)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Total: R$ \(String(format: "%.2f", reservation.price))")
                    .font(.subheadline)
                    .bold()
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detalhes da Reserva")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(.black) // <- isso altera a cor do botão de voltar
    }
}
