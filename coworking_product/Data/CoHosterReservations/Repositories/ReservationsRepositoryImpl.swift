import Foundation

// MARK: - Repository Protocol for CoHoster Reservations (Data Layer)
// MARK: - Implementation using URLSession directly (Removed APIService dependency)
struct CoHosterReservationsRepositoryImpl: CoHosterReservationsRepository {
    private let baseURL = "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro"

    func fetch(hosterId: String, status: CoHosterReservationStatus?) async throws -> [CoHosterReservation] {
        var components = URLComponents(string: "\(baseURL)/reservations")
        var items: [URLQueryItem] = [URLQueryItem(name: "hosterId", value: hosterId)]
        
        if let status = status {
            let dtoStatus: CoHosterReservationDTO.Status
            switch status {
            case .pending: dtoStatus = .pending
            case .confirmed: dtoStatus = .confirmed
            case .canceled: dtoStatus = .canceled
            case .refused: dtoStatus = .refused
            }
            items.append(URLQueryItem(name: "status", value: dtoStatus.rawValue))
        }
        
        components?.queryItems = items
        
        guard let url = components?.url else {
            throw NSError(domain: "CoHosterRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "CoHosterRepository", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"])
        }

        switch http.statusCode {
        case 200:
            let dtos = try JSONDecoder().decode([CoHosterReservationDTO].self, from: data)
            return dtos.map { CoHosterReservation(dto: $0) }
        case 404:
            return []
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "CoHosterRepository", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erro \(http.statusCode): \(body)"])
        }
    }

    func updateStatus(id: String, spaceId: String, date: Date, status: CoHosterReservationStatus) async throws {
        // Map domain status to DTO status
        let dtoStatus: CoHosterReservationDTO.Status
        switch status {
        case .pending: dtoStatus = .pending
        case .confirmed: dtoStatus = .confirmed
        case .canceled: dtoStatus = .canceled
        case .refused: dtoStatus = .refused
        }
        
        // Extract exact datetime string from ID for safer matching
        // ID format: "spaceId|datetime"
        let parts = id.components(separatedBy: "|")
        guard parts.count >= 2 else {
           throw NSError(domain: "CoHosterRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID da reserva inválido para extração de data."])
        }
        let dateString = parts[1]

        guard let url = URL(string: "\(baseURL)/reservations") else {
             throw NSError(domain: "CoHosterRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "action": "update_status",
            "spaceId": spaceId,
            "datetime": dateString,
            "status": dtoStatus.rawValue
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "CoHosterRepository", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"])
        }
        
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Erro \(http.statusCode)"
            throw NSError(domain: "CoHosterRepository", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
}
