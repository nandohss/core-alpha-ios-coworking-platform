// Data/CoHosterSpaceManagement/Mappers/FacilityCategoryMapper.swift
// Conversão entre FacilityCategoryDTO e FacilityCategory (domínio)

import Foundation

extension FacilityCategory {
    init(dto: FacilityCategoryDTO) {
        self.id = dto.id
        self.name = dto.name
        self.facilities = dto.facilities.map { Facility(dto: $0) }
    }
}

extension FacilityCategoryDTO {
    init(domain: FacilityCategory) {
        self.id = domain.id
        self.name = domain.name
        self.facilities = domain.facilities.map { FacilityDTO(domain: $0) }
    }
}
