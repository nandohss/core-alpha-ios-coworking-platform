
// MARK: - Model de Reserva
struct Reserva: Encodable {
    let userId: String
    let coworkingId: String
    let data: String
    let horarioInicio: String
    let horarioFim: String
}

// MARK: - ViewModel de Reserva
class ReservaViewModel: ObservableObject {
    @Published var status: String? = nil
    @Published var isSending = false
    @Published var errorMessage: String? = nil

    func enviarReserva(_ reserva: Reserva) async {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/reserva") else {
            self.errorMessage = "URL inválida"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(reserva)
            isSending = true
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.status = "Reserva enviada com sucesso!"
                }
            } else {
                throw URLError(.badServerResponse)
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Erro ao enviar reserva: \(error.localizedDescription)"
            }
        }
        isSending = false
    }
}


//
//  ReservationSummaryView.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import SwiftUI

struct ReservationSummaryView: View {
    var coworking: CoworkingModel
    var selectedDate: Date
    var selectedHours: [Int]
    var totalPrice: Double

    @State private var selectedPaymentMethod = "Cartão de Crédito"
    @State private var voucherCode = ""
    @State private var navigateToSuccess = false

    let paymentMethods: [(label: String, icon: String)] = [
        ("Cartão de Crédito", "creditcard.fill"),
        ("Pix", "qrcode")
    ]

    let cryptoMethods: [(label: String, icon: String)] = [
        ("Bitcoin", "bitcoinsign.circle.fill"),
        ("Ethereum", "e.circle.fill"),
        ("Solana", "s.circle.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Resumo da Reserva")
                    .font(.title2)
                    .bold()

                // Informações principais
                VStack(spacing: 12) {
                    infoRow(label: "Espaço", systemImage: "building.2.fill", value: coworking.name)
                    infoRow(label: "Data", systemImage: "calendar", value: formattedDate)
                    infoRow(label: "Horários", systemImage: "clock", value: selectedHours.map { "\($0)h" }.joined(separator: ", "))
                }

                // Valor total
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "banknote.fill")
                            .foregroundColor(.gray)

                        Text("R$ \(String(format: "%.2f", totalPrice))")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }

                // Métodos de pagamento
                VStack(alignment: .leading, spacing: 12) {
                    Text("Método de Pagamento")
                        .font(.headline)

                    ForEach(paymentMethods, id: \.label) { method in
                        PaymentOptionView(
                            label: method.label,
                            iconName: method.icon,
                            isSelected: selectedPaymentMethod == method.label,
                            onTap: { selectedPaymentMethod = method.label }
                        )
                    }
                }

                // Criptomoedas
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pagar com Criptomoeda")
                        .font(.headline)

                    ForEach(cryptoMethods, id: \.label) { method in
                        PaymentOptionView(
                            label: method.label,
                            iconName: method.icon,
                            isSelected: selectedPaymentMethod == method.label,
                            onTap: { selectedPaymentMethod = method.label }
                        )
                    }
                }

                // Campo de voucher com botão aplicar
                VStack(alignment: .leading, spacing: 8) {
                    Text("Código de Voucher (opcional)")
                        .font(.headline)

                    HStack {
                        TextField("Digite aqui...", text: $voucherCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button("Aplicar") {
                            print("Voucher aplicado: \(voucherCode)")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .foregroundColor(.black)
                    }
                }

                // Botão de finalizar reserva
                Button(action: {
                    navigateToSuccess = true
                }) {
                    Text("Finalizar Reserva")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .cornerRadius(10)
                }

                NavigationLink(
                    destination: ReservationSuccessView(
                        coworking: coworking,
                        selectedDate: selectedDate,
                        selectedHours: selectedHours,
                        paymentMethod: selectedPaymentMethod
                    ),
                    isActive: $navigateToSuccess
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
        .navigationTitle("Confirmação")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    func infoRow(label: String, systemImage: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: systemImage)
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
