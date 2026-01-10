// Domain/CoworkerReservations/Models/CoworkerReservation.swift
import Foundation

public struct CoworkerReservation: Identifiable, Equatable {
    public var id: String { "\(spaceId)_\(dateReservation)" }
    public let spaceId: String
    public let datetimeReservation: String
    public let status: String
    public let userId: String
    public let dateReservation: String
    public let hourReservation: String
    public let createdAt: String

    public init(
        spaceId: String,
        datetimeReservation: String,
        status: String,
        userId: String,
        dateReservation: String,
        hourReservation: String,
        createdAt: String
    ) {
        self.spaceId = spaceId
        self.datetimeReservation = datetimeReservation
        self.status = status
        self.userId = userId
        self.dateReservation = dateReservation
        self.hourReservation = hourReservation
        self.createdAt = createdAt
    }
    
    // Helper para formatação de data
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "pt_BR")
        if let date = formatter.date(from: dateReservation) {
            formatter.dateStyle = .long
            return formatter.string(from: date)
        }
        return dateReservation
    }

    // Helper para formatação de hora
    public var formattedHour: String {
        return "\(hourReservation)h"
    }

    public enum ReservationStatus: String, CaseIterable {
        case pending = "PENDING"
        case confirmed = "CONFIRMED"
        case canceled = "CANCELED"
        case refused = "REFUSED"
        
        public var title: String {
            switch self {
            case .pending: return "Pendente"
            case .confirmed: return "Confirmada"
            case .canceled: return "Cancelada"
            case .refused: return "Recusada"
            }
        }
    }
    
    public var statusEnum: ReservationStatus {
        if let exact = ReservationStatus(rawValue: status) { return exact }
        if let uppercased = ReservationStatus(rawValue: status.uppercased()) { return uppercased }
        return .pending
    }
}
