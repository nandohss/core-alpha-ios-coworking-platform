
// MARK: - Model da Reserva
struct ReservaResumo: Identifiable, Decodable {
    let id: String
    let coworkingId: String
    let data: String
    let horarioInicio: String
    let horarioFim: String
    let status: String
}

// MARK: - ViewModel
class MinhasReservasViewModel: ObservableObject {
    @Published var reservas: [ReservaResumo] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func carregarReservas(userId: String) async {
        guard let url = URL(string: "https://sua-api.amazonaws.com/prod/reserva?userId=\(userId)") else {
            self.errorMessage = "URL inválida"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([ReservaResumo].self, from: data)
            DispatchQueue.main.async {
                self.reservas = decoded
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Erro ao carregar reservas: \(error.localizedDescription)"
            }
        }
    }
}


//
//  MyReservationsView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct MyReservationsView: View {
    let reservations: [Reservation] = [
        Reservation(
            coworkingName: "CoWorking XPTO",
            imageName: "coworking1",
            date: Date(),
            hours: [9, 10, 11],
            price: 150.0
        ),
        Reservation(
            coworkingName: "Vila Madalena Hub",
            imageName: "coworking2",
            date: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
            hours: [14, 15],
            price: 100.0
        )
    ]

    var body: some View {
        List {
            ForEach(reservations) { reservation in
                NavigationLink(destination: QRCodeDetailView(reservation: reservation)) {
                    HStack(spacing: 12) {
                        Image(reservation.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 60)
                            .cornerRadius(8)
                            .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(reservation.coworkingName)
                                .font(.headline)

                            Text("\(reservation.formattedDate) • \(reservation.formattedHours)")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Text("Total: R$ \(String(format: "%.2f", reservation.price))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Minhas Reservas")
    }
}


#Preview {
    NavigationStack {
        MyReservationsView()
    }
}
