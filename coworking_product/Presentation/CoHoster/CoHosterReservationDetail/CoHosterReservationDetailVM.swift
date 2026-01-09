import SwiftUI
import Foundation

@MainActor
final class CoHosterReservationDetailVM: ObservableObject {
    @Published var reservation: CoHosterReservationViewData
    @Published var isProcessing: Bool = false
    @Published var showConfirmAlert: Bool = false
    @Published var pendingAction: PendingAction? = nil
    @Published var errorMessage: String? = nil
    
    private let updateUseCase: any UpdateCoHosterReservationStatusUseCase
    private let onSuccess: () async -> Void

    enum PendingAction {
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

    init(
        reservation: CoHosterReservationViewData,
        updateUseCase: any UpdateCoHosterReservationStatusUseCase,
        onSuccess: @escaping () async -> Void
    ) {
        self.reservation = reservation
        self.updateUseCase = updateUseCase
        self.onSuccess = onSuccess
    }
    
    func requestApprove() {
        self.pendingAction = .approve
        self.showConfirmAlert = true
    }
    
    func requestReject() {
        self.pendingAction = .reject
        self.showConfirmAlert = true
    }
    
    func confirmAction() async {
        guard let action = pendingAction else { return }
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            switch action {
            case .approve:
                try await updateUseCase.execute(
                    id: reservation.id,
                    spaceId: reservation.spaceId,
                    date: reservation.startDate,
                    status: .confirmed
                )
            case .reject:
                try await updateUseCase.execute(
                    id: reservation.id,
                    spaceId: reservation.spaceId,
                    date: reservation.startDate,
                    status: .refused
                )
            case .cancel:
                // Cancel not implemented in case yet but supported in theory
                // Assuming cancel sets to Cancelled
                // For now, only approve/reject were requested.
                break
            }
            await onSuccess()
        } catch {
            self.errorMessage = "Erro ao atualizar reserva: \(error.localizedDescription)"
        }
    }
}
