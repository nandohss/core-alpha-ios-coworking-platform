// Domain/CoworkerReservations/Repositories/CoworkerReservationsRepository.swift
import Foundation

public protocol CoworkerReservationsRepository {
    func fetchReservations(userId: String) async throws -> [CoworkerReservation]
    func fetchCoworkingSpaces() async throws -> [String: CoworkingInfo]
    func fetchAllSpaces() async throws -> [CoworkingSpace]
    
    // Novas funções para criação e verificação
    func createReservation(request: CoworkerReservationRequest) async throws
    func checkAvailability(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String]
}
