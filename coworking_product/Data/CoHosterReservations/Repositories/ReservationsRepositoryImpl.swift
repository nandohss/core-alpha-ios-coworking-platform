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

    func updateStatus(id: String, spaceId: String, date: Date, status: CoHosterReservationStatus) async throws {
        // Map domain status to DTO status
        let dtoStatus: CoHosterReservationDTO.Status
        switch status {
        case .pending: dtoStatus = .pending
        case .confirmed: dtoStatus = .confirmed
        case .canceled: dtoStatus = .canceled
        case .refused: dtoStatus = .refused
        }
        
        // Format date to ISO8601 string expected by backend (assuming exact match needed)
        // Backend uses ISO8601 UTC.
        // Use the ID (which contains the exact raw datetime string) to avoid valid date formatting mismatches
        // ID format: "spaceId|datetime"
        let parts = id.components(separatedBy: "|")
        guard parts.count >= 2 else {
           throw NSError(domain: "CoHosterReservationsRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID da reserva inválido para extração de data."])
        }
        let dateString = parts[1] // The exact string stored in DynamoDB

        
        try await APIService.updateReservationStatus(spaceId: spaceId, datetime: dateString, status: dtoStatus)
    }
}
