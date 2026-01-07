// Data/CoHosterSpaceManagement/Repositories/SpaceManagementRepository.swift
// Protocolo do repositório para gerenciamento de espaços

import Foundation

protocol SpaceManagementRepository {
    func fetchSpace(spaceId: String) async throws -> ManagedSpace
    func saveSpace(_ space: ManagedSpace) async throws
    func uploadPhoto(data: Data, filename: String, spaceId: String) async throws -> URL
    func deletePhoto(url: URL, spaceId: String) async throws
    func saveFacilities(spaceId: String, facilityIDs: [String]) async throws
    func saveAvailability(spaceId: String, weekdays: Set<Int>) async throws
    func saveRules(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws
    func updateFlags(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws
    func fetchFacilities() async throws -> [Facility]
    func saveAll(
        space: ManagedSpace,
        facilityIDs: [String],
        weekdays: Set<Int>,
        minDurationMinutes: Int,
        bufferMinutes: Int,
        autoApprove: Bool
    ) async throws
}
