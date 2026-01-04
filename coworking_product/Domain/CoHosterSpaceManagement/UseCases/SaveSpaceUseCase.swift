// Domain/CoHosterSpaceManagement/UseCases/SaveSpaceUseCase.swift
// Protocolo do caso de uso para salvar informações básicas do espaço

import Foundation

public protocol SaveSpaceUseCase {
    func execute(_ space: ManagedSpace) async throws
}
