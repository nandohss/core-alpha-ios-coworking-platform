//
//  model.swift
//  coworking_product
//
//  Created by Fernando on 25/12/25.
//

import Foundation

public struct CoHosterReservation: Equatable, Hashable, Identifiable {
    public let id: String
    public let spaceId: String
    public let userId: String
    public let hosterId: String
    public let start: Date
    public let end: Date
    public let status: CoHosterReservationStatus
    public let spaceName: String?
    public let userName: String?
    public let userEmail: String?
    public let capacity: Int?
    public let dateReservation: String?
    public let totalValue: Double?
    public let hourlyRate: Double?
    public let dailyRate: Double?
    public let isFullDay: Bool?
    public let createdAt: Date?
}

public enum CoHosterReservationStatus: Equatable, Hashable {
    case pending
    case confirmed
    case canceled
    case refused
}
