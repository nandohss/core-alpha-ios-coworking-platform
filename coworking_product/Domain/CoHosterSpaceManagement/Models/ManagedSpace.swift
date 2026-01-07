// Domain/CoHosterSpaceManagement/Models/ManagedSpace.swift
// Entidade de domínio para espaço gerenciado

import Foundation

public struct ManagedSpace: Identifiable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var capacity: Int
    public var pricePerHour: Double
    public var description: String
    public var isEnabled: Bool
    public var weekdays: [Int]
    public var amenities: [String]
    public var rules: String
    public var startTime: String?
    public var endTime: String?
    
    public init(id: String, title: String, capacity: Int, pricePerHour: Double, description: String, isEnabled: Bool, weekdays: [Int] = [], amenities: [String] = [], rules: String = "", startTime: String? = nil, endTime: String? = nil) {
        self.id = id
        self.title = title
        self.capacity = capacity
        self.pricePerHour = pricePerHour
        self.description = description
        self.isEnabled = isEnabled
        self.weekdays = weekdays
        self.amenities = amenities
        self.rules = rules
        self.startTime = startTime
        self.endTime = endTime
    }
}
extension ManagedSpace {
    init(dto: ManagedSpaceDTO) {
        // Map PT-BR weekday abbreviations to indices (1 = Seg ... 7 = Dom)
        let mapDiaParaIndice: [String: Int] = [
            "Seg": 1, "Ter": 2, "Qua": 3, "Qui": 4, "Sex": 5, "Sáb": 6, "Sab": 6, "Dom": 7
        ]

        let weekdaysInts: [Int] = (dto.diasSemana ?? [])
            .compactMap { abreviacao in
                // Try direct match first (including accented form like "Sáb")
                if let val = mapDiaParaIndice[abreviacao] {
                    return val
                }
                // Fallback: normalize common variations (remove accent from "á")
                let normalizado = abreviacao
                    .replacingOccurrences(of: "á", with: "a")
                    .replacingOccurrences(of: "Á", with: "A")
                return mapDiaParaIndice[normalizado]
            }

        self.init(
            id: dto.id,
            title: dto.title,
            capacity: dto.capacity,
            pricePerHour: dto.pricePerHour,
            description: dto.description,
            isEnabled: dto.isEnabled,
            weekdays: weekdaysInts,
            amenities: dto.amenities ?? [],
            rules: dto.regras ?? "",
            startTime: dto.horaInicio,
            endTime: dto.horaFim
        )
    }
}

