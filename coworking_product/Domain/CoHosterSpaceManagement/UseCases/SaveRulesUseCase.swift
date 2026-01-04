// Domain/CoHosterSpaceManagement/UseCases/SaveRulesUseCase.swift
// Protocolo do caso de uso: Salvar regras de reserva do espaço

import Foundation

public protocol SaveRulesUseCase {
    func execute(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws
}
