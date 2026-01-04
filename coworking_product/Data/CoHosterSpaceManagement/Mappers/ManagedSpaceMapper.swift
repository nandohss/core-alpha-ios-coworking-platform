// Data/CoHosterSpaceManagement/Mappers/ManagedSpaceMapper.swift
// Conversão entre ManagedSpaceDTO e ManagedSpace (domínio)

import Foundation

extension ManagedSpace {
    init(dto: ManagedSpaceDTO) {
        self.id = dto.id
        self.title = dto.title
        self.capacity = dto.capacity
        self.pricePerHour = dto.pricePerHour
        self.description = dto.description
        self.isEnabled = dto.isEnabled
    }
}

extension ManagedSpaceDTO {
    init(domain: ManagedSpace) {
        self.id = domain.id
        self.title = domain.title
        self.capacity = domain.capacity
        self.pricePerHour = domain.pricePerHour
        self.description = domain.description
        self.isEnabled = domain.isEnabled
    }
}
