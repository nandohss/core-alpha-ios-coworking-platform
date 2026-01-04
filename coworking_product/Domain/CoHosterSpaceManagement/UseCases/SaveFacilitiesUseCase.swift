// Domain/CoHosterSpaceManagement/UseCases/SaveFacilitiesUseCase.swift
// Protocolo do caso de uso: Salvar facilidades do espaço

import Foundation

public protocol SaveFacilitiesUseCase {
    func execute(spaceId: String, facilityIDs: [String]) async throws
}
