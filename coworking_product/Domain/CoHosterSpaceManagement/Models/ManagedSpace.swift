// Domain/CoHosterSpaceManagement/Models/ManagedSpace.swift
// Entidade de domínio para espaço gerenciado

import Foundation

public struct ManagedSpace: Identifiable, Equatable, Hashable {
    public let id: String
    public var title: String
    public var capacity: Int
    public var pricePerHour: Double
    public var pricePerDay: Double?
    public var description: String
    public var isEnabled: Bool
    public var weekdays: [Int]
    public var amenities: [String]
    public var rules: String
    public var startTime: String?
    public var endTime: String?
    public var minDurationMinutes: Int
    public var bufferMinutes: Int

    public var isFullDay: Bool
    public var email: String?
    public var ddd: String?
    public var phoneNumber: String?
    public var fullPhoneNumber: String?
    public var companyName: String?
    
    public init(id: String, title: String, capacity: Int, pricePerHour: Double, pricePerDay: Double? = nil, description: String, isEnabled: Bool, weekdays: [Int] = [], amenities: [String] = [], rules: String = "", startTime: String? = nil, endTime: String? = nil, minDurationMinutes: Int = 60, bufferMinutes: Int = 15, isFullDay: Bool = false, email: String? = nil, ddd: String? = nil, phoneNumber: String? = nil, fullPhoneNumber: String? = nil, companyName: String? = nil) {
        self.id = id
        self.title = title
        self.capacity = capacity
        self.pricePerHour = pricePerHour
        self.pricePerDay = pricePerDay
        self.description = description
        self.isEnabled = isEnabled
        self.weekdays = weekdays
        self.amenities = amenities
        self.rules = rules
        self.startTime = startTime
        self.endTime = endTime
        self.minDurationMinutes = minDurationMinutes
        self.bufferMinutes = bufferMinutes
        self.isFullDay = isFullDay
        self.email = email
        self.ddd = ddd
        self.phoneNumber = phoneNumber
        self.fullPhoneNumber = fullPhoneNumber
        self.companyName = companyName
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
            pricePerDay: dto.pricePerDay,
            description: dto.description,
            isEnabled: dto.isEnabled,
            weekdays: weekdaysInts,
            amenities: dto.amenities ?? [],
            rules: dto.regras ?? "",
            startTime: dto.horaInicio,
            endTime: dto.horaFim,
            minDurationMinutes: dto.minDurationMinutes ?? 60,
            bufferMinutes: dto.bufferMinutes ?? 15,
            isFullDay: dto.diaInteiro ?? false,
            email: dto.email,
            ddd: dto.ddd,
            phoneNumber: dto.numeroTelefone,
            fullPhoneNumber: dto.telefoneCompleto,
            companyName: dto.razaoSocial
        )
    }
}

