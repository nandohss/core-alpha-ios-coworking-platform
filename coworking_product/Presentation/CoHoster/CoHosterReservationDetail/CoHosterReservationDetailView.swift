import SwiftUI
import CoreImage.CIFilterBuiltins

struct CoHosterReservationDetailView: View {
    @StateObject private var viewModel: CoHosterReservationDetailVM
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: CoHosterReservationDetailVM) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                infoCards
                actionSection
            }
            .padding(16)
        }
        .navigationTitle("Reserva")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Voltar", systemImage: "chevron.left")
                }
            }
        }
        .alert(viewModel.pendingAction?.title ?? "Confirmação", isPresented: $viewModel.showConfirmAlert, presenting: viewModel.pendingAction) { action in
            Button(action.confirmLabel, role: action.role) {
                Task {
                    await viewModel.confirmAction()
                    dismiss()
                }
            }
            Button("Voltar", role: .cancel) { }
        } message: { action in
             Text("Esta ação não pode ser desfeita.")
        }
        .overlay {
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.reservation.spaceName)
                .font(.title3).fontWeight(.semibold)
            Text("\(formattedDateRange(start: viewModel.reservation.startDate, end: viewModel.reservation.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                statusBadge(viewModel.reservation.status)
                Spacer()
                Text(totalBRL(viewModel.reservation.total))
                    .font(.headline)
            }
        }
    }
    
    private var infoCards: some View {
        VStack(spacing: 12) {
            GroupBox {
                LabeledContent("Hóspede", value: viewModel.reservation.guestName)
                LabeledContent("E-mail", value: viewModel.reservation.guestEmail)
                if let cpf = viewModel.reservation.cpf, !cpf.isEmpty {
                    LabeledContent("CPF", value: cpf)
                }
                if let cnpj = viewModel.reservation.cnpj, !cnpj.isEmpty {
                    LabeledContent("CNPJ", value: cnpj)
                }
                if let phone = viewModel.reservation.guestPhone, !phone.isEmpty {
                    LabeledContent("Telefone", value: phone)
                }
            }
            GroupBox {
                LabeledContent("Espaço", value: viewModel.reservation.spaceName)
                LabeledContent("Capacidade", value: "\(viewModel.reservation.capacity) pessoas")
                if let room = viewModel.reservation.roomLabel { LabeledContent("Sala", value: room) }
            }
            GroupBox {
                LabeledContent("Data", value: formatDay(viewModel.reservation.startDate))
                LabeledContent("Horário", value: formattedTimeRange(start: viewModel.reservation.startDate, end: viewModel.reservation.endDate))
                LabeledContent("Criada em", value: formatDate(viewModel.reservation.createdAt))
                LabeledContent("Código", value: viewModel.reservation.code)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if viewModel.reservation.status == .pending {
                // Botões de Ação (Estilo App)
                HStack(spacing: 16) {
                    
                    // Botão Recusar
                    Button {
                        viewModel.requestReject()
                    } label: {
                        Text("Recusar").bold()
                    }
                    .buttonStyle(NavBtnStyle(background: Color.gray.opacity(0.2), foreground: .red))

                    // Botão Aprovar
                    Button {
                        viewModel.requestApprove()
                    } label: {
                        Text("Aprovar").bold()
                    }
                    .buttonStyle(NavBtnStyle(background: .black, foreground: .white))
                }
            }
        }
        .disabled(viewModel.isProcessing)
    }
    
    // Helpers
    private func totalBRL(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f.string(from: .init(value: value)) ?? "R$ \(value)"
    }
    private func formattedDateRange(start: Date, end: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "dd/MM/yyyy HH:mm"
        return "\(df.string(from: start)) – \(df.string(from: end))"
    }
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }
    private func statusBadge(_ status: CoHosterReservationViewData.Status) -> some View {
        Text(status.label)
            .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
    private func formatDay(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
    private func formattedTimeRange(start: Date, end: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.dateFormat = "HH:mm"
        return "\(df.string(from: start)) – \(df.string(from: end))"
    }
}

// MARK: - Preview
#Preview("CoHosterReservationDetailView") {
    let mock = CoHosterReservationViewData(
        id: "rsv_123",
        spaceId: "space_123",
        code: "ABC123",
        spaceName: "Sala de Reuniões A",
        roomLabel: "Sala 2",
        capacity: 6,
        startDate: Date().addingTimeInterval(3600),
        endDate: Date().addingTimeInterval(7200),
        createdAt: Date().addingTimeInterval(-86400),
        total: 199.90,
        status: .approved,
        guestName: "João Silva",
        guestEmail: "joao@example.com",
        guestPhone: "+55 (11) 91234-5678",
        cpf: "123.456.789-00",
        cnpj: nil
    )
    let repo = CoHosterReservationsRepositoryImpl()
    let useCase = UpdateCoHosterReservationStatusUseCaseImpl(repository: repo)
    let vm = CoHosterReservationDetailVM(reservation: mock, updateUseCase: useCase, onSuccess: {})
    
    return CoHosterReservationDetailView(viewModel: vm)
}
