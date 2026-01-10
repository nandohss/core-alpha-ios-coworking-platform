// Domain/CoworkerReservations/UseCases/FetchCoworkerReservationsUseCase.swift
import Foundation

public protocol FetchCoworkerReservationsUseCase {
    func execute(userId: String) async throws -> (reservations: [CoworkerReservation], spaces: [String: CoworkingInfo])
}

public class RealFetchCoworkerReservationsUseCase: FetchCoworkerReservationsUseCase {
    private let repository: CoworkerReservationsRepository

    public init(repository: CoworkerReservationsRepository) {
        self.repository = repository
    }

    public func execute(userId: String) async throws -> (reservations: [CoworkerReservation], spaces: [String: CoworkingInfo]) {
        // Fetch reservations and spaces concurrently
        async let reservationsTask = repository.fetchReservations(userId: userId)
        async let spacesTask = repository.fetchCoworkingSpaces()
        
        let (reservations, spaces) = try await (reservationsTask, spacesTask)
        return (reservations, spaces)
    }
}
