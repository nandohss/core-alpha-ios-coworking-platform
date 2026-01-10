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
            Text(viewModel.primary.spaceName)
                .font(.title3).fontWeight(.semibold)
            Text("\(formattedDateRange(start: viewModel.primary.startDate, end: viewModel.primary.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                statusBadge(viewModel.primary.status)
                Spacer()
                Text(totalBRL(viewModel.primary.isFullDay ? (viewModel.primary.dailyRate ?? 0) : viewModel.reservations.reduce(0) { $0 + $1.total }))
                    .font(.headline)
            }
        }
    }
    
    private var infoCards: some View {
        VStack(spacing: 12) {
            GroupBox {
                LabeledContent("Coworker", value: viewModel.primary.guestName)
                LabeledContent("E-mail", value: viewModel.primary.guestEmail)
                if let cpf = viewModel.primary.cpf, !cpf.isEmpty {
                    LabeledContent("CPF", value: cpf)
                }
                if let cnpj = viewModel.primary.cnpj, !cnpj.isEmpty {
                    LabeledContent("CNPJ", value: cnpj)
                }
                if let phone = viewModel.primary.guestPhone, !phone.isEmpty {
                    LabeledContent("Telefone", value: phone)
                }
            }
            GroupBox {
                LabeledContent("Espaço", value: viewModel.primary.spaceName)
                LabeledContent("Capacidade", value: "\(viewModel.primary.capacity) pessoas")
                if let room = viewModel.primary.roomLabel { LabeledContent("Sala", value: room) }
            }
            GroupBox {
                LabeledContent("Data", value: formatDay(viewModel.primary.startDate))
                // Mostrar todos os horários
                let times = viewModel.reservations
                    .sorted { $0.startDate < $1.startDate }
                    .map { formatTimeOnly($0.startDate) }
                    .joined(separator: ", ")
                LabeledContent("Horários", value: times)
                
                LabeledContent("Criada em", value: formatDate(viewModel.primary.createdAt))
                LabeledContent("Código", value: viewModel.primary.code)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            if viewModel.primary.status == .pending {
                // Botões de Ação (Estilo App)
                HStack(spacing: 16) {
                    
                    // Botão Recusar
                    Button {
                        viewModel.requestReject()
                    } label: {
                        Text("Recusar todos").bold()
                    }
                    .buttonStyle(NavBtnStyle(background: Color.gray.opacity(0.2), foreground: .red))

                    // Botão Aprovar
                    Button {
                        viewModel.requestApprove()
                    } label: {
                        Text("Aprovar todos").bold()
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
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        df.dateFormat = "dd/MM/yyyy"
        return df.string(from: start) // Use start date only as group is same day
    }
    private func formatDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
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
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }
    private func formatTimeOnly(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "pt_BR")
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        df.dateFormat = "HH:mm"
        return df.string(from: date)
    }
}


