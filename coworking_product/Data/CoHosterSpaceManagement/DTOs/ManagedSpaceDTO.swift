// Data/CoHosterSpaceManagement/DTOs/ManagedSpaceDTO.swift
// DTO para ManagedSpace (usado na API ou banco)

import Foundation

struct ManagedSpaceDTO: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let capacity: Int
    let pricePerHour: Double
    let description: String
    let isEnabled: Bool
}
