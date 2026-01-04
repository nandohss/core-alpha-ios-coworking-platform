// Data/CoHosterSpaceManagement/DTOs/FacilityDTO.swift
// DTO para Facility (usado na API ou banco)

import Foundation

struct FacilityDTO: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let systemImage: String?
}
