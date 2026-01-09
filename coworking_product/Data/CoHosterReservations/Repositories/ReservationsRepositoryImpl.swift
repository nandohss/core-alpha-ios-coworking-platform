import Foundation

// MARK: - Repository Protocol for CoHoster Reservations (Data Layer)
// MARK: - Default Implementation using APIService
struct CoHosterReservationsRepositoryImpl: CoHosterReservationsRepository {
    func fetch(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation] {
        let dtos = try await APIService.fetchCoHosterReservations(hosterId: hosterId, status: status.map { 
            switch $0 {
            case .pending: return .pending
            case .confirmed: return .confirmed
            case .canceled: return .canceled
            case .refused: return .refused
            }
        })
        return dtos.map { CoHosterReservation(dto: $0) }
    }
}
