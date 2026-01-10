import Foundation

public struct CoworkerReservationRequest: Encodable {
    public let spaceId_reservation: String
    public let date_reservation: String
    public let hours_reservation: [String]
    public let status: String
    public let userId: String
    
    public init(spaceId: String, date: String, hours: [String], userId: String, status: String = "PENDING") {
        self.spaceId_reservation = spaceId
        self.date_reservation = date
        self.hours_reservation = hours
        self.userId = userId
        self.status = status
    }
}
