// Data/CoHosterSpaceManagement/UseCases/RealSaveSpaceAllUseCase.swift
// Implementação real do caso de uso agregado usando o repositório

import Foundation

struct RealSaveSpaceAllUseCase: SaveSpaceAllUseCase {
    let repository: SpaceManagementRepository

    func execute(
        space: ManagedSpace,
        facilityIDs: [String],
        weekdays: Set<Int>,
        minDurationMinutes: Int,
        bufferMinutes: Int,
        autoApprove: Bool
    ) async throws {
        try await repository.saveAll(
            space: space,
            facilityIDs: facilityIDs,
            weekdays: weekdays,
            minDurationMinutes: minDurationMinutes,
            bufferMinutes: bufferMinutes,
            autoApprove: autoApprove
        )
    }
}
