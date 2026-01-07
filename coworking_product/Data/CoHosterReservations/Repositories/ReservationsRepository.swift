import Foundation

// MARK: - Repository Protocol for CoHoster Reservations (Data Layer)
protocol CoHosterReservationsRepository {
    func fetch(hosterId: String, status: CoHosterReservationDTO.Status?) async throws -> [CoHosterReservation]
}

// MARK: - Default Implementation using APIService
struct CoHosterReservationsRepositoryImpl: CoHosterReservationsRepository {
    func fetch(hosterId: String, status: CoHosterReservationDTO.Status?) async throws -> [CoHosterReservation] {
        let dtos = try await APIService.fetchCoHosterReservations(hosterId: hosterId, status: status)
        return dtos.map { CoHosterReservation(dto: $0) }
    }
}
