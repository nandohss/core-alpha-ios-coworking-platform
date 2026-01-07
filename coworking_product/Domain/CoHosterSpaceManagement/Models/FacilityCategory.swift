// Domain/CoHosterSpaceManagement/Models/FacilityCategory.swift
// Categoria de facilidades (domínio)

import Foundation

public struct FacilityCategory: Identifiable, Hashable, Equatable {
    public let id: String
    public let name: String
    public var facilities: [Facility]
    
    public init(id: String, name: String, facilities: [Facility]) {
        self.id = id
        self.name = name
        self.facilities = facilities
    }
}
