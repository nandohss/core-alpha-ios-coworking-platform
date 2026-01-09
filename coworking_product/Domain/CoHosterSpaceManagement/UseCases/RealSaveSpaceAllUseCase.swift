// Data/CoHosterSpaceManagement/UseCases/RealSaveSpaceAllUseCase.swift
// Implementação real do caso de uso agregado usando o repositório

import Foundation

struct RealSaveSpaceAllUseCase: SaveSpaceAllUseCase {
    let repository: SpaceManagementRepository

    func execute(
        space: ManagedSpace,
        pricePerDay: Double?,
        facilityIDs: [String],
        weekdays: Set<Int>,
        minDurationMinutes: Int,
        bufferMinutes: Int,
        autoApprove: Bool,
        rules: String,
        startTime: String?,
        endTime: String?,
        isFullDay: Bool,
        email: String?,
        ddd: String?,
        phoneNumber: String?,
        companyName: String?
    ) async throws {
        try await repository.saveAll(
            space: space,
            pricePerDay: pricePerDay,
            facilityIDs: facilityIDs,
            weekdays: weekdays,
            minDurationMinutes: minDurationMinutes,
            bufferMinutes: bufferMinutes,
            autoApprove: autoApprove,
            rules: rules,
            startTime: startTime,
            endTime: endTime,
            isFullDay: isFullDay,
            email: email,
            ddd: ddd,
            phoneNumber: phoneNumber,
            companyName: companyName
        )
    }
}
