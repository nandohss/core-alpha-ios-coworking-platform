// Data/CoHosterSpaceManagement/DTOs/FacilityDTO.swift
// DTO para Facility (usado na API ou banco)

import Foundation

struct FacilityDTO: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let systemImage: String?
}
extension FacilityDTO {
    /// Convenience initializer to create a FacilityDTO from a plain name.
    /// Uses the name as a stable `id` when no backend ID is available.
    init(name: String) {
        self.id = name
        self.name = name
        self.systemImage = nil
    }

    /// Builds an array of FacilityDTO from amenity names, de-duplicating by name.
    static func fromAmenityNames(_ names: [String]) -> [FacilityDTO] {
        var seen = Set<String>()
        var result: [FacilityDTO] = []
        for n in names {
            let trimmed = n.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, !seen.contains(trimmed) else { continue }
            seen.insert(trimmed)
            result.append(FacilityDTO(name: trimmed))
        }
        return result
    }
}

