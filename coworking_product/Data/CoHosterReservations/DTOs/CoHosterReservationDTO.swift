import Foundation

struct CoHosterReservationDTO: Decodable, Identifiable, Equatable, Hashable {
    enum Status: String, Decodable, CaseIterable {
        case pending = "PENDING"
        case confirmed = "CONFIRMED"
        case canceled = "CANCELED"
        case refused = "REFUSED"
    }
    
    let id: String
    let spaceId: String
    let userId: String
    let hosterId: String
    let startDate: String
    let endDate: String
    let status: Status
    let spaceName: String?
    let userName: String?
    let userEmail: String?
    let capacity: Int?
    let dateReservation: String?
    let totalValue: Double?
    let hourlyRate: Double?
    let dailyRate: Double?
    let isFullDay: Bool?
    let createdAt: String?
}
