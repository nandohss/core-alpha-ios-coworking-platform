// Data/CoworkerReservations/Repositories/CoworkerReservationsRepositoryImpl.swift
import Foundation

// DTO para decodificação da API
struct CoworkerReservationDTO: Decodable {
    let spaceId_reservation: String
    let datetime_reservation: String
    let status: String
    let userId: String
    let date_reservation: String
    let hour_reservation: String
    let created_at: String
    
    func toDomain() -> CoworkerReservation {
        return CoworkerReservation(
            spaceId: spaceId_reservation,
            datetimeReservation: datetime_reservation,
            status: status,
            userId: userId,
            dateReservation: date_reservation,
            hourReservation: hour_reservation,
            createdAt: created_at
        )
    }
}

public class CoworkerReservationsRepositoryImpl: CoworkerReservationsRepository {
    private let baseURL = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro")!
    
    public init() {}
    
    public func fetchReservations(userId: String) async throws -> [CoworkerReservation] {
        guard let url = URL(string: "\(baseURL.absoluteString)/reservations/user?userId=\(userId)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let dtos = try JSONDecoder().decode([CoworkerReservationDTO].self, from: data)
        return dtos.map { $0.toDomain() }
    }
    
    public func fetchCoworkingSpaces() async throws -> [String: CoworkingInfo] {
        guard let url = URL(string: "\(baseURL.absoluteString)/spaces") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let spaces = try JSONDecoder().decode([CoworkingInfo].self, from: data)
        
        var mapa: [String: CoworkingInfo] = [:]
        for space in spaces {
            mapa[space.spaceId] = space
        }
        return mapa
    }
    public func createReservation(request: CoworkerReservationRequest) async throws {
        guard let url = URL(string: "\(baseURL.absoluteString)/reservations") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
             let body = String(data: data, encoding: .utf8) ?? ""
             throw NSError(domain: "CoworkerRepository", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erro \(httpResponse.statusCode): \(body)"])
        }
    }
    
    public func fetchAllSpaces() async throws -> [CoworkingSpace] {
        guard let url = URL(string: "\(baseURL.absoluteString)/spaces") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let dtos = try JSONDecoder().decode([CoworkingSpaceDTO].self, from: data)
        return dtos.map { CoworkingSpaceMapper.toDomain(dto: $0) }
    }

    private struct CheckAvailabilityResponseDTO: Decodable {
        let available: Bool
        let conflicts: [String]
    }

    public func checkAvailability(spaceId: String, date: String, hours: [String], hosterId: String) async throws -> [String] {
        // GET /reservations?spaceId=...&date=...&hours=...&hosterId=...
        var components = URLComponents(string: "\(baseURL.absoluteString)/reservations")
        
        // Encode hours as JSON string as per legacy logic
        let hoursJSON = String(data: try JSONEncoder().encode(hours), encoding: .utf8) ?? "[]"
        
        components?.queryItems = [
            URLQueryItem(name: "spaceId", value: spaceId),
            URLQueryItem(name: "date", value: date), // Format: yyyy-MM-dd
            URLQueryItem(name: "hours", value: hoursJSON),
            URLQueryItem(name: "hosterId", value: hosterId)
        ]
        
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? ""
            print("❌ Availability Check Failed: \(httpResponse.statusCode) - \(body)")
            throw NSError(domain: "CoworkerRepository", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erro \(httpResponse.statusCode): \(body)"])
        }
        
        // Decode new availability format
        let dto = try JSONDecoder().decode(CheckAvailabilityResponseDTO.self, from: data)
        return dto.conflicts
    }
    public func fetchSpaceReservations(hosterId: String, spaceId: String) async throws -> [CoworkerReservation] {
        // GET /reservations?hosterId=...
        var components = URLComponents(string: "\(baseURL.absoluteString)/reservations")
        components?.queryItems = [
            URLQueryItem(name: "hosterId", value: hosterId)
        ]
        
        guard let url = components?.url else { throw URLError(.badURL) }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let dtos = try JSONDecoder().decode([CoworkerReservationDTO].self, from: data)
        let allReservations = dtos.map { $0.toDomain() }
        
        // Filter by spaceId locally
        return allReservations.filter { $0.spaceId == spaceId }
    }
}
