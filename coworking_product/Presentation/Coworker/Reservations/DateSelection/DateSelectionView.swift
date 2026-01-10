import SwiftUI

struct DateSelectionView: View {
    let coworking: Coworking
    @Binding var selectedTab: Int
    
    @StateObject private var viewModel: DateSelectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(coworking: Coworking, selectedTab: Binding<Int>) {
        self.coworking = coworking
        self._selectedTab = selectedTab
        self._viewModel = StateObject(wrappedValue: ReservationViewModelFactory.makeDateSelectionViewModel(space: coworking.toDomain()))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // Calendário Customizado
                    CustomCalendarView(
                        selectedDate: $viewModel.selectedDate,
                        allowedWeekdays: viewModel.space.availability.weekdays
                     )
                    .onChange(of: viewModel.selectedDate) { _ in
                        viewModel.onDateChanged()
                    }
                    .onAppear {
                        viewModel.onDateChanged()
                    }

                    if !viewModel.isFullDay {
                        Text("Escolha os horários")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                    }

                    if viewModel.isLoading {
                        ProgressView("Carregando horários...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        if viewModel.isFullDay {
                           VStack(spacing: 8) {
                                Text("Reserva de dia inteiro habilitada")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.top)
                                Text("O valor cobrado será referente à diária.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 12) {
                                ForEach(viewModel.availableHours, id: \.self) { hour in
                                    let isSelected = viewModel.selectedHours.contains(hour)
                                    let isReserved = viewModel.reservedHours.contains(hour)
                                    let isPast = viewModel.isHourPast(hour)

                                    HourCell(hour: hour, isSelected: isSelected, isReserved: isReserved || isPast) {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.toggleHour(hour)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 100)
                }
                .padding()
            }

            VStack(spacing: 12) {
                if viewModel.isSelectionValid {
                    HStack {
                        Text("\(viewModel.totalHours)h selecionadas")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        Spacer()

                        Text("Total: R$ \(String(format: "%.2f", viewModel.totalPrice))")
                            .font(.headline)
                            .bold()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.totalPrice)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                NavigationLink(
                    destination: ReservationSummaryViewWrapper(
                        coworking: coworking,
                        selectedDate: viewModel.selectedDate,
                        selectedHours: viewModel.selectedHours.sorted(),
                        totalPrice: viewModel.totalPrice,
                        selectedTab: $selectedTab
                    )
                ) {
                    Text("Confirmar Reserva")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isSelectionValid ? Color.black : Color.gray)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                .disabled(!viewModel.isSelectionValid)
            }
            .padding(.bottom, 16)
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Escolha uma data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
             viewModel.update(space: coworking.toDomain())
        }
        .onChange(of: coworking.isFullDay) { _ in
             viewModel.update(space: coworking.toDomain())
        }
    }
}

private struct HourCell: View {
    let hour: Int
    let isSelected: Bool
    let isReserved: Bool
    let onTap: () -> Void

    var body: some View {
        Text("\(hour)h")
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(8)
            .foregroundColor(foregroundColor)
            .onTapGesture {
                guard !isReserved else { return }
                onTap()
            }
            .disabled(isReserved)
    }

    private var backgroundColor: Color {
        if isReserved { return .clear }
        if isSelected { return Color.gray.opacity(0.9) }
        return Color.gray.opacity(0.10)
    }
    
    private var foregroundColor: Color {
        if isReserved { return .gray.opacity(0.6) } // Lighter gray to indicate disabled
        if isSelected { return .white } // Selected text
        return .black // Default text
    }
}
