//
//  te.swift
//  coworking_product
//
//  Created by Fernando on 25/12/25.
//

import Foundation

extension CoHosterReservation {
    init(dto: CoHosterReservationDTO) {
        self.id = dto.id
        self.spaceId = dto.spaceId
        self.userId = dto.userId
        self.hosterId = dto.hosterId
        self.start = ISO8601DateFormatter().date(from: dto.startDate) ?? Date()
        self.end = ISO8601DateFormatter().date(from: dto.endDate) ?? Date()
        self.status = CoHosterReservationStatus(dto.status)
        self.spaceName = dto.spaceName
        self.userName = dto.userName
        self.userEmail = dto.userEmail
    }
}

extension CoHosterReservationStatus {
    init(_ s: CoHosterReservationDTO.Status) {
        switch s {
        case .pending:   self = .pending
        case .confirmed: self = .confirmed
        case .canceled:  self = .canceled
        case .refused:   self = .refused
        }
    }
}
