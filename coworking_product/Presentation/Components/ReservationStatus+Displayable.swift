import SwiftUI

// Extension for Coworker Status
extension CoworkerReservation.ReservationStatus: ReservationStatusDisplayable {
    var color: Color {
        switch self {
        case .pending: return .yellow
        case .confirmed: return .green
        case .canceled: return .red
        case .refused: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        case .refused: return "xmark"
        }
    }
    // title is already defined in the Enum
}

// Extension for CoHoster Status
extension CoHosterReservationStatus: ReservationStatusDisplayable {
    var title: String {
        switch self {
        case .confirmed: return "Confirmada"
        case .pending:   return "Pendente"
        case .canceled:  return "Cancelada"
        case .refused:   return "Recusada"
        }
    }

    var color: Color {
        switch self {
        case .confirmed: return .green
        case .pending:   return .yellow
        case .canceled:  return .red
        case .refused:   return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .confirmed: return "checkmark.circle.fill"
        case .refused: return "xmark"
        case .canceled: return "xmark.circle.fill"
        }
    }
}
