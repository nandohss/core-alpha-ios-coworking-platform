import SwiftUI
import Amplify

struct ReservationSummaryViewWrapper: View {
    var coworking: Coworking
    var selectedDate: Date
    var selectedHours: [Int]
    var totalPrice: Double

    @Binding var selectedTab: Int

    var body: some View {
        NavigationStack {
            ReservationSummaryView(
                coworking: coworking,
                selectedDate: selectedDate,
                selectedHours: selectedHours,
                totalPrice: totalPrice,
                selectedTab: $selectedTab
            )
        }
    }
}

struct ReservationSummaryView: View {
    var coworking: Coworking
    var selectedDate: Date
    var selectedHours: [Int]
    var totalPrice: Double

    @Binding var selectedTab: Int

    @State private var selectedPaymentMethod = "Cartão de Crédito"
    @State private var voucherCode = ""
    @State private var showSuccessView = false

    @StateObject private var viewModel = ReservaViewModel()

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
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Resumo da Reserva")
                        .font(.title2)
                        .bold()

                    VStack(spacing: 12) {
                        infoRow(label: "Espaço", systemImage: "building.2.fill", value: coworking.nome)
                        infoRow(label: "Data", systemImage: "calendar", value: formattedDate)
                        infoRow(label: "Horários", systemImage: "clock", value: selectedHours.map { "\($0)h" }.joined(separator: ", "))
                    }

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

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Método de Pagamento")
                            .font(.headline)

                        ForEach(paymentMethods, id: \.label) { method in
                            PaymentOptionView(
                                label: method.label,
                                iconName: method.icon,
                                isSelected: selectedPaymentMethod == method.label,
                                onTap: { selectedPaymentMethod = method.label },
                                isDisabled: false
                            )
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pagar com Criptomoeda")
                            .font(.headline)

                        Text("Em breve disponível")
                            .font(.caption)
                            .foregroundColor(.gray)

                        ForEach(cryptoMethods, id: \.label) { method in
                            PaymentOptionView(
                                label: method.label,
                                iconName: method.icon,
                                isSelected: false, // sempre falso, já que está desabilitado
                                onTap: { },
                                isDisabled: true
                            )
                        }
                    }

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

                    Button(action: {
                        Task {
                            let dateStr = formatDateOnly(selectedDate)
                            let hourStrings = selectedHours.map { String($0) }

                            let conflitos = await viewModel.verificarDisponibilidade(
                                spaceId: coworking.id,
                                date: dateStr,
                                hours: hourStrings
                            )

                            if conflitos.isEmpty {
                                if let attributes = try? await Amplify.Auth.fetchUserAttributes(),
                                   let userId = attributes.first(where: { $0.key.rawValue == "sub" })?.value {

                                    let reserva = Reserva(
                                        spaceId_reservation: coworking.id,
                                        date_reservation: dateStr,
                                        hours_reservation: hourStrings,
                                        status: "reserved",
                                        userId: userId
                                    )

                                    await viewModel.enviarReserva(reserva)

                                    if viewModel.status != nil {
                                        print("✅ Status atualizado: \(viewModel.status!)")
                                        showSuccessView = true
                                    } else {
                                        print("⚠️ Status ainda nulo")
                                    }

                                } else {
                                    viewModel.errorMessage = "Usuário não autenticado"
                                }
                            } else {
                                viewModel.errorMessage = "Horários já reservados: \(conflitos.joined(separator: ", "))"
                            }
                        }
                    }) {
                        if viewModel.isSending {
                            ProgressView()
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(10)
                        } else {
                            Text("Finalizar Reserva")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(viewModel.isSending)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Confirmação")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showSuccessView) {
            ReservationSuccessView(
                coworking: coworking,
                selectedDate: selectedDate,
                selectedHours: selectedHours,
                paymentMethod: selectedPaymentMethod,
                selectedTab: $selectedTab
            )
        }
        .toolbar(.hidden, for: .tabBar)
    }

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

    func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
