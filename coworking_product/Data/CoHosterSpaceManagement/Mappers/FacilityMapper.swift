// Data/CoHosterSpaceManagement/Mappers/FacilityMapper.swift
// Conversão entre FacilityDTO e Facility (domínio)

import Foundation

extension Facility {
    init(dto: FacilityDTO) {
        self.id = dto.id
        self.name = dto.name
        self.systemImage = dto.systemImage
    }
}

extension FacilityDTO {
    init(domain: Facility) {
        self.id = domain.id
        self.name = domain.name
        self.systemImage = domain.systemImage
    }
}
