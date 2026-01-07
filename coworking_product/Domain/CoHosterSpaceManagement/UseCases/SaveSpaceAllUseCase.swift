//
//  SaveSpaceAllUseCase.swift
//  coworking_product
//
//  Created by Fernando on 04/01/26.
//

// Domain/CoHosterSpaceManagement/UseCases/SaveSpaceAllUseCase.swift
// Caso de uso agregado: salvar todas as informações do espaço em uma única chamada

import Foundation

public protocol SaveSpaceAllUseCase {
    func execute(
        space: ManagedSpace,
        facilityIDs: [String],
        weekdays: Set<Int>,
        minDurationMinutes: Int,
        bufferMinutes: Int,
        autoApprove: Bool,
        rules: String,
        startTime: String?,
        endTime: String?
    ) async throws
}

