import SwiftUI
import CoreImage.CIFilterBuiltins

struct CoHosterReservationDetailView: View {
    let reservation: CoHosterReservationViewData
    @State private var isProcessing = false
    @State private var showConfirmAlert = false
    @State private var pendingAction: PendingAction? = nil
    @Environment(\.dismiss) private var dismiss

    var approveAction: ((String) async throws -> Void)? = nil
    var rejectAction: ((String) async throws -> Void)? = nil
    var cancelAction: ((String) async throws -> Void)? = nil
    
    private enum PendingAction {
        case approve, reject, cancel
        var title: String {
            switch self {
            case .approve: return "Confirmar aprovação?"
            case .reject: return "Confirmar recusa?"
            case .cancel: return "Confirmar cancelamento?"
            }
        }
        var confirmLabel: String {
            switch self {
            case .approve: return "Aprovar"
            case .reject: return "Recusar"
            case .cancel: return "Cancelar"
            }
        }
        var role: ButtonRole? {
            switch self {
            case .approve: return nil
            case .reject, .cancel: return .destructive
            }
        }
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
        .alert(pendingAction?.title ?? "Confirmação", isPresented: $showConfirmAlert, presenting: pendingAction) { action in
            Button(action.confirmLabel, role: action.role) {
                switch action {
                case .approve:
                    Task { await runApprove() }
                case .reject:
                    Task { await runReject() }
                case .cancel:
                    Task { await runCancel() }
                }
            }
            Button("Voltar", role: .cancel) { }
        } message: { action in
            Text("Esta ação não pode ser desfeita.")
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reservation.spaceName)
                .font(.title3).fontWeight(.semibold)
            Text("\(formattedDateRange(start: reservation.startDate, end: reservation.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack {
                statusBadge(reservation.status)
                Spacer()
                Text(totalBRL(reservation.total))
                    .font(.headline)
            }
        }
    }
    
    private var infoCards: some View {
        VStack(spacing: 12) {
            GroupBox {
                LabeledContent("Hóspede", value: reservation.guestName)
                LabeledContent("E-mail", value: reservation.guestEmail)
                if let cpf = reservation.cpf, !cpf.isEmpty {
                    LabeledContent("CPF", value: cpf)
                }
                if let cnpj = reservation.cnpj, !cnpj.isEmpty {
                    LabeledContent("CNPJ", value: cnpj)
                }
                if let phone = reservation.guestPhone, !phone.isEmpty {
                    LabeledContent("Telefone", value: phone)
                }
            }
            GroupBox {
                LabeledContent("Espaço", value: reservation.spaceName)
                LabeledContent("Capacidade", value: "\(reservation.capacity) pessoas")
                if let room = reservation.roomLabel { LabeledContent("Sala", value: room) }
            }
            GroupBox {
                LabeledContent("Data", value: formatDay(reservation.startDate))
                LabeledContent("Horário", value: formattedTimeRange(start: reservation.startDate, end: reservation.endDate))
                LabeledContent("Criada em", value: formatDate(reservation.createdAt))
                LabeledContent("Código", value: reservation.code)
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 10) {
            if reservation.status == .pending {
                HStack {
                    Button {
                        pendingAction = .approve
                        showConfirmAlert = true
                    } label: { labelIcon("Aprovar", "checkmark.circle") }
                    .buttonStyle(.borderedProminent)
                    
                    Button(role: .destructive) {
                        pendingAction = .reject
                        showConfirmAlert = true
                    } label: { labelIcon("Recusar", "xmark.circle") }
                    .buttonStyle(.bordered)
                }
            }
            
            if reservation.status != .cancelled && reservation.status != .rejected {
                HStack {
                    Button(role: .destructive) {
                        pendingAction = .cancel
                        showConfirmAlert = true
                    } label: { labelIcon("Cancelar", "trash") }
                    .buttonStyle(.bordered)
                }
            }
        }
        .disabled(isProcessing)
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
    private func labelIcon(_ text: String, _ system: String) -> some View {
        Label(text, systemImage: system)
            .frame(maxWidth: .infinity)
    }
    private func statusBadge(_ status: CoHosterReservationViewData.Status) -> some View {
        Text(status.label)
            .font(.caption).padding(.horizontal, 10).padding(.vertical, 6)
            .background(status.color.opacity(0.15))
            .foregroundColor(status.color)
            .clipShape(Capsule())
    }
    private func whatsappURL(phone: String?) -> URL? {
        guard let phone = phone?.filter({ $0.isNumber }), !phone.isEmpty else { return nil }
        return URL(string: "https://wa.me/\(phone)")
    }
    private func taskWrapper(_ work: @escaping () async throws -> Void) {
        isProcessing = true
        Task {
            do {
                try await work()
                dismiss()
            } catch {
                // TODO: surface error to user (toast/alert)
                print("Reservation action failed: \(error)")
            }
            isProcessing = false
        }
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
    
    private func runApprove() async {
        await withTaskCancellationHandler {} operation: {
            taskWrapper { try await approveAction?(reservation.id) }
        }
    }
    private func runReject() async {
        await withTaskCancellationHandler {} operation: {
            taskWrapper { try await rejectAction?(reservation.id) }
        }
    }
    private func runCancel() async {
        await withTaskCancellationHandler {} operation: {
            taskWrapper { try await cancelAction?(reservation.id) }
        }
    }
}

struct CoHosterReservationViewData: Identifiable, Hashable {
    enum Status: String {
        case pending, approved, rejected, cancelled, checkedIn
        var label: String {
            switch self {
            case .pending: return "Pendente"
            case .approved: return "Aprovada"
            case .rejected: return "Recusada"
            case .cancelled: return "Cancelada"
            case .checkedIn: return "Check-in"
            }
        }
        var color: Color {
            switch self {
            case .pending: return .orange
            case .approved: return .blue
            case .rejected: return .red
            case .cancelled: return .gray
            case .checkedIn: return .green
            }
        }
    }
    let id: String
    let code: String
    let spaceName: String
    let roomLabel: String?
    let capacity: Int
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let total: Double
    let status: Status
    let guestName: String
    let guestEmail: String
    let guestPhone: String?
    let cpf: String?
    let cnpj: String?
}

// MARK: - Preview
#Preview("CoHosterReservationDetailView") {
    let mock = CoHosterReservationViewData(
        id: "rsv_123",
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
    return CoHosterReservationDetailView(
        reservation: mock,
        approveAction: { _ in },
        rejectAction: { _ in },
        cancelAction: { _ in }
    )
}
