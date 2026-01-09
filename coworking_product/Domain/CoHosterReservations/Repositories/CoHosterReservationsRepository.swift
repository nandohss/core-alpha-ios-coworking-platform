import Foundation

// MARK: - Repository Protocol for CoHoster Reservations (Domain Layer)
public protocol CoHosterReservationsRepository {
    func fetch(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation]
    func updateStatus(id: String, spaceId: String, date: Date, status: CoHosterReservationStatus) async throws
}
