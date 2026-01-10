import Foundation

public protocol CheckReservationAvailabilityUseCase {
    func execute(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String]
}

public class RealCheckReservationAvailabilityUseCase: CheckReservationAvailabilityUseCase {
    private let repository: CoworkerReservationsRepository
    
    public init(repository: CoworkerReservationsRepository) {
        self.repository = repository
    }
    
    public func execute(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String] {
        return try await repository.checkAvailability(spaceId: spaceId, date: date, hours: hours, hosterId: hosterId)
    }
}
