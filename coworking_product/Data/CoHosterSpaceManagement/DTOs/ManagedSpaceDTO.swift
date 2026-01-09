// Data/CoHosterSpaceManagement/DTOs/ManagedSpaceDTO.swift
// DTO para ManagedSpace (usado na API ou banco)

import Foundation

struct ManagedSpaceDTO: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let capacity: Int
    let pricePerHour: Double
    let pricePerDay: Double?
    let description: String
    let isEnabled: Bool
    let diasSemana: [String]?
    let amenities: [String]?
    let regras: String?
    let horaInicio: String?
    let horaFim: String?
    let minDurationMinutes: Int?
    let bufferMinutes: Int?

    let diaInteiro: Bool?
    let email: String?
    let ddd: String?
    let numeroTelefone: String?
    let telefoneCompleto: String?
    let razaoSocial: String?

    enum CodingKeys: String, CodingKey {
        case id = "spaceId"
        case title = "name"
        case capacity
        case pricePerHour = "precoHora"
        case pricePerDay = "precoDia"
        case description = "descricao"
        case isEnabled = "availability"
        case diasSemana
        case amenities
        case regras
        case horaInicio
        case horaFim
        case minDurationMinutes
        case bufferMinutes

        case diaInteiro
        case email
        case ddd
        case numeroTelefone
        case telefoneCompleto
        case razaoSocial
    }
}

struct SpaceAggregatedUpdateDTO: Codable {
    let id: String
    let title: String
    let capacity: Int
    let pricePerHour: Double
    let pricePerDay: Double?
    let description: String
    let isEnabled: Bool
    let autoApprove: Bool
    let facilityIDs: [String]
    let weekdays: [Int]
    let minDurationMinutes: Int?
    let bufferMinutes: Int?
    let regras: String?
    let horaInicio: String?
    let horaFim: String?
    let isFullDay: Bool?
    let email: String?
    let ddd: String?
    let numeroTelefone: String?
    let telefoneCompleto: String?
    let razaoSocial: String?
}
