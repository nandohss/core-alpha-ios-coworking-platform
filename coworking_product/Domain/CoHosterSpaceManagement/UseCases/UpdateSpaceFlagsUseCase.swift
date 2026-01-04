// Domain/CoHosterSpaceManagement/UseCases/UpdateSpaceFlagsUseCase.swift
// Protocolo do caso de uso: Atualizar flags do espaço (habilitar, auto-aprovação, etc)

import Foundation

public protocol UpdateSpaceFlagsUseCase {
    func execute(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws
}
