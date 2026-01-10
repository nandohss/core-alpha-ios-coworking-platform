import Foundation
import Amplify

@MainActor
class ReservationSummaryViewModel: ObservableObject {
    @Published var status: String? = nil
    @Published var isSending = false
    @Published var errorMessage: String? = nil

    private let createReservationUseCase: CreateCoworkerReservationUseCase
    private let checkAvailabilityUseCase: CheckReservationAvailabilityUseCase
    
    init(
        createReservationUseCase: CreateCoworkerReservationUseCase = RealCreateCoworkerReservationUseCase(repository: CoworkerReservationsRepositoryImpl()),
        checkAvailabilityUseCase: CheckReservationAvailabilityUseCase = RealCheckReservationAvailabilityUseCase(repository: CoworkerReservationsRepositoryImpl())
    ) {
        self.createReservationUseCase = createReservationUseCase
        self.checkAvailabilityUseCase = checkAvailabilityUseCase
    }

    /// Envia reserva com userId atual
    func enviarReserva(spaceId: String, date: String, hours: [String]) async {
        isSending = true
        defer { isSending = false }

        guard let attributes = try? await Amplify.Auth.fetchUserAttributes(),
              let userId = attributes.first(where: { $0.key.rawValue == "sub" })?.value else {
            self.errorMessage = "Usuário não autenticado"
            return
        }

        let request = CoworkerReservationRequest(
            spaceId: spaceId,
            date: date,
            hours: hours,
            userId: userId
        )

        do {
            try await createReservationUseCase.execute(request: request)
            self.status = "Solicitação de reserva enviada com sucesso e aguardando aprovação do co-hoster."
        } catch {
            self.errorMessage = "Erro ao enviar reserva: \(error.localizedDescription)"
        }
    }

    /// Verifica se há conflitos de horário
    func verificarDisponibilidade(spaceId: String, date: String, hours: [String], hosterId: String) async -> [String] {
        do {
            return try await checkAvailabilityUseCase.execute(spaceId: spaceId, date: date, hours: hours, hosterId: hosterId)
        } catch {
            print("❌ Erro na verificação de disponibilidade: \(error.localizedDescription)")
            return []
        }
    }
}
