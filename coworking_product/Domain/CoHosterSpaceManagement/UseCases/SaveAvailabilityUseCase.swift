// Domain/CoHosterSpaceManagement/UseCases/SaveAvailabilityUseCase.swift
// Protocolo do caso de uso: Salvar disponibilidade do espaço

import Foundation

public protocol SaveAvailabilityUseCase {
    func execute(spaceId: String, weekdays: Set<Int>) async throws
}
