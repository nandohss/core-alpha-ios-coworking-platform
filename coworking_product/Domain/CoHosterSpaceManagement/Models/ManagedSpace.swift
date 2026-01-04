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
    
    public init(id: String, title: String, capacity: Int, pricePerHour: Double, description: String, isEnabled: Bool) {
        self.id = id
        self.title = title
        self.capacity = capacity
        self.pricePerHour = pricePerHour
        self.description = description
        self.isEnabled = isEnabled
    }
}
