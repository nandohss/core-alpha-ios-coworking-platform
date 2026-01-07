// Data/CoHosterSpaceManagement/Mappers/ManagedSpaceMapper.swift
// Conversão entre ManagedSpaceDTO e ManagedSpace (domínio)

import Foundation

extension ManagedSpaceDTO {
    init(domain: ManagedSpace) {
        self.id = domain.id
        self.title = domain.title
        self.capacity = domain.capacity
        self.pricePerHour = domain.pricePerHour
        self.description = domain.description
        self.isEnabled = domain.isEnabled
        let reverseMap: [Int: String] = [1: "Seg", 2: "Ter", 3: "Qua", 4: "Qui", 5: "Sex", 6: "Sáb", 7: "Dom"]
        let labels = domain.weekdays.compactMap { reverseMap[$0] }
        self.diasSemana = labels
        self.amenities = domain.amenities
        self.regras = domain.rules
        self.horaInicio = domain.startTime
        self.horaFim = domain.endTime
    }
}

