import Foundation

public protocol CheckReservationAvailabilityUseCase {
    func execute(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String]
    func fetchReservations(hosterId: String, spaceId: String) async throws -> [CoworkerReservation]
}

public class RealCheckReservationAvailabilityUseCase: CheckReservationAvailabilityUseCase {
    private let repository: CoworkerReservationsRepository
    
    public init(repository: CoworkerReservationsRepository) {
        self.repository = repository
    }
    
    public func execute(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String] {
        return try await repository.checkAvailability(spaceId: spaceId, date: date, hours: hours, hosterId: hosterId)
    }

    public func fetchReservations(hosterId: String, spaceId: String) async throws -> [CoworkerReservation] {
        return try await repository.fetchSpaceReservations(hosterId: hosterId, spaceId: spaceId)
    }
}
