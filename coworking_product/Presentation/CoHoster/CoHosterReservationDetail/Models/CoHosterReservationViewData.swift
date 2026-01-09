import SwiftUI
import Foundation

struct CoHosterReservationViewData: Identifiable, Hashable {
    enum Status: String {
        case pending, approved, rejected, cancelled, checkedIn
        var label: String {
            switch self {
            case .pending: return "Pendente"
            case .approved: return "Aprovada"
            case .rejected: return "Recusada"
            case .cancelled: return "Cancelada"
            case .checkedIn: return "Check-in"
            }
        }
        var color: Color {
            switch self {
            case .pending: return .orange
            case .approved: return Color(red: 0, green: 0.6, blue: 0.2)
            case .rejected: return .red
            case .cancelled: return .gray
            case .checkedIn: return .green
            }
        }
    }
    let id: String
    let spaceId: String
    let code: String
    let spaceName: String
    let roomLabel: String?
    let capacity: Int
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    let total: Double
    let status: Status
    let guestName: String
    let guestEmail: String
    let guestPhone: String?
    let cpf: String?
    let cnpj: String?
}
