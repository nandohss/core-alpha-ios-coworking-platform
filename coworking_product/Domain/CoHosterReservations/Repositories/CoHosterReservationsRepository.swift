import Foundation

// MARK: - Repository Protocol for CoHoster Reservations (Domain Layer)
public protocol CoHosterReservationsRepository {
    func fetch(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation]
}
