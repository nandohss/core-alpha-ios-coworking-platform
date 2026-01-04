// Data/CoHosterSpaceManagement/DTOs/FacilityCategoryDTO.swift
// DTO para FacilityCategory (usado na API ou banco)
import Foundation

struct FacilityCategoryDTO: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let facilities: [FacilityDTO]
}

