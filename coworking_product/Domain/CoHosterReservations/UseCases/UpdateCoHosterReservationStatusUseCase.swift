import Foundation

protocol UpdateCoHosterReservationStatusUseCase {
    func execute(id: String, spaceId: String, date: Date, status: CoHosterReservationStatus) async throws
}

struct UpdateCoHosterReservationStatusUseCaseImpl: UpdateCoHosterReservationStatusUseCase {
    private let repository: CoHosterReservationsRepository
    
    init(repository: CoHosterReservationsRepository) {
        self.repository = repository
    }
    
    func execute(id: String, spaceId: String, date: Date, status: CoHosterReservationStatus) async throws {
        try await repository.updateStatus(id: id, spaceId: spaceId, date: date, status: status)
    }
}
