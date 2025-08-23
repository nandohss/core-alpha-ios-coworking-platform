import SwiftUI

struct DateSelectionView: View {
    var coworking: Coworking

    @State private var selectedDate = Date()
    @State private var selectedHours: Set<Int> = []
    @State private var reservedHours: [Int] = []
    @State private var isLoading = false
    @StateObject private var viewModel = ReservaViewModel()

    let availableHours = Array(8...20)

    var totalHours: Int { selectedHours.count }
    var pricePerHour: Double { coworking.precoHora ?? 0.0 }
    var totalPrice: Double { Double(totalHours) * pricePerHour }
    var isSelectionValid: Bool { totalHours > 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Escolha uma data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)

                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: Date()...Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                        displayedComponents: [.date]
                    )
                    .labelsHidden()
                    .datePickerStyle(.graphical)
                    .accentColor(.black)
                    .frame(height: 280)
                    .onChange(of: selectedDate) { _ in
                        Task { await carregarHorasReservadas() }
                    }

                    Text("Escolha os horários")
                        .font(.headline)
                        .padding(.top)

                    if isLoading {
                        ProgressView("Carregando horários...")
                    } else {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                            ForEach(availableHours, id: \.self) { hour in
                                let isSelected = selectedHours.contains(hour)
                                let isReserved = reservedHours.contains(hour)

                                Text("\(hour)h")
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .background(isReserved
                                                ? Color.gray.opacity(0.01)
                                                : isSelected
                                                ? Color.gray.opacity(0.9)
                                                  : Color.gray.opacity(0.10))
                                    .cornerRadius(8)
                                    .foregroundColor(isReserved ? .white : .black)
                                    .onTapGesture {
                                        guard !isReserved else { return }
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            if isSelected {
                                                selectedHours.remove(hour)
                                            } else {
                                                selectedHours.insert(hour)
                                            }
                                        }
                                    }
                                    .disabled(isReserved)
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding()
            }

            VStack(spacing: 12) {
                if isSelectionValid {
                    HStack {
                        Text("\(totalHours)h selecionadas")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("Total: R$ \(String(format: "%.2f", totalPrice))")
                            .font(.headline)
                            .bold()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: totalPrice)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                NavigationLink(
                    destination: ReservationSummaryView(
                        coworking: coworking,
                        selectedDate: selectedDate,
                        selectedHours: selectedHours.sorted(),
                        totalPrice: totalPrice
                    )
                ) {
                    Text("Confirmar Reserva")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isSelectionValid ? Color.black : Color.gray)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .disabled(!isSelectionValid)
            }
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(true)
        .onAppear {
            Task { await carregarHorasReservadas() }
        }
    }

    func carregarHorasReservadas() async {
        isLoading = true
        let all = availableHours.map { String($0) }
        let reservadas = await viewModel.verificarDisponibilidade(
            spaceId: coworking.id,
            date: formatDateOnly(selectedDate),
            hours: all
        )
        reservedHours = reservadas.compactMap { Int($0) }
        isLoading = false
    }

    func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
