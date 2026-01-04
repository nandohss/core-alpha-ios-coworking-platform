// Domain/CoHosterSpaceManagement/Models/Facility.swift
// Entidade de domínio para uma facilidade

import Foundation

public struct Facility: Identifiable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let systemImage: String?
    
    public init(id: String, name: String, systemImage: String?) {
        self.id = id
        self.name = name
        self.systemImage = systemImage
    }
}
