// Domain/CoworkerReservations/Models/CoworkingInfo.swift
import Foundation

public struct CoworkingInfo: Decodable, Equatable {
    public let spaceId: String
    public let name: String
    public let imagemUrl: String?
    
    public init(spaceId: String, name: String, imagemUrl: String?) {
        self.spaceId = spaceId
        self.name = name
        self.imagemUrl = imagemUrl
    }
}
