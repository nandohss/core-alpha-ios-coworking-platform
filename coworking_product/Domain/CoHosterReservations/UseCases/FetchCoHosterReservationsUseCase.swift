import Foundation

// MARK: - Use Case Protocol (Domain Layer)
protocol FetchCoHosterReservationsUseCase {
    func execute(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation]
}

// MARK: - Default Implementation
struct FetchCoHosterReservationsUseCaseImpl: FetchCoHosterReservationsUseCase {
    private let repository: CoHosterReservationsRepository

    init(repository: CoHosterReservationsRepository) {
        self.repository = repository
    }

    func execute(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation] {
        // Map Domain status to DTO status if needed (same cases here)
        // For now, repository accepts DTO status; adjust repository to accept Domain if preferred.
        return try await repository.fetch(hosterId: hosterId, status: status)
    }
}
