// Domain/CoHosterSpaceManagement/UseCases/FetchFacilityCategoriesUseCase.swift
// Caso de uso: Buscar categorias de facilidades disponíveis no domínio

import Foundation

public protocol FetchFacilityCategoriesUseCase {
    func execute() async throws -> [FacilityCategory]
}
