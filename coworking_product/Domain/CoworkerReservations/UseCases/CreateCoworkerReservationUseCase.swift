import Foundation

public protocol CreateCoworkerReservationUseCase {
    func execute(request: CoworkerReservationRequest) async throws
}

public class RealCreateCoworkerReservationUseCase: CreateCoworkerReservationUseCase {
    private let repository: CoworkerReservationsRepository
    
    public init(repository: CoworkerReservationsRepository) {
        self.repository = repository
    }
    
    public func execute(request: CoworkerReservationRequest) async throws {
        try await repository.createReservation(request: request)
    }
}
