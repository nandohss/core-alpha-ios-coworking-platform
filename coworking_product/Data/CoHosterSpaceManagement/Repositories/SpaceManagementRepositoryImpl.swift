//
//  SpaceManagementRepositoryImpl.swift
//  coworking_product
//
//  Created by Fernando on 03/01/26.
//

// Data/CoHosterSpaceManagement/Repositories/SpaceManagementRepositoryImpl.swift
// Implementação concreta do SpaceManagementRepository
import Foundation


final class SpaceManagementRepositoryImpl: SpaceManagementRepository {
    private let baseURL: URL
    private let session: URLSession
    private let authTokenProvider: () -> String?

    init(baseURL: URL, session: URLSession = .shared, authTokenProvider: @escaping () -> String?) {
        self.baseURL = baseURL
        self.session = session
        self.authTokenProvider = authTokenProvider
    }

    func fetchSpace(spaceId: String) async throws -> ManagedSpace {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/spaces"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "spaceId", value: spaceId)]
        print("➡️ FetchSpace URL:", comps.url?.absoluteString ?? "nil")
        var request = URLRequest(url: comps.url!)
        request.httpMethod = "GET"
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            print("🌐 FetchSpace status:", http.statusCode)
            print("🌐 FetchSpace headers:", http.allHeaderFields)
        }
        try ensureSuccess(response: response, data: data)
        print("⬅️ FetchSpace OK — bytes:", data.count)
        if let json = String(data: data, encoding: .utf8) {
            print("📥 FetchSpace JSON:\n\(json)")
        } else {
            print("📥 FetchSpace (non-UTF8 data) bytes:", data.count)
        }
        do {
            let dto = try JSONDecoder().decode(ManagedSpaceDTO.self, from: data)
            let rawDias = dto.diasSemana ?? []
            let map: [String: Int] = [
                "Dom": 1, "Seg": 2, "Ter": 3, "Qua": 4, "Qui": 5, "Sex": 6, "Sáb": 7, "Sab": 7
            ]
            let weekdayIndices = rawDias.compactMap { map[$0] }
            return ManagedSpace(
                id: dto.id,
                title: dto.title,
                capacity: dto.capacity,
                pricePerHour: dto.pricePerHour,
                description: dto.description,
                isEnabled: dto.isEnabled,
                weekdays: weekdayIndices,
                amenities: dto.amenities ?? []
            )
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ DecodingError.keyNotFound:", key.stringValue, "path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
            print("   debugDescription:", context.debugDescription)
            throw DecodingError.keyNotFound(key, context)
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ DecodingError.typeMismatch:", type, "path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
            print("   debugDescription:", context.debugDescription)
            throw DecodingError.typeMismatch(type, context)
        } catch let DecodingError.valueNotFound(type, context) {
            print("❌ DecodingError.valueNotFound:", type, "path:", context.codingPath.map { $0.stringValue }.joined(separator: "."))
            print("   debugDescription:", context.debugDescription)
            throw DecodingError.valueNotFound(type, context)
        } catch let DecodingError.dataCorrupted(context) {
            print("❌ DecodingError.dataCorrupted:", context.debugDescription)
            if let underlying = context.underlyingError {
                print("   underlying:", underlying.localizedDescription)
            }
            throw DecodingError.dataCorrupted(context)
        } catch {
            let err = error as Error
            print("❌ FetchSpace decode error:", err.localizedDescription)
            throw err
        }
    }

    func saveSpace(_ space: ManagedSpace) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/spaces/\(space.id)"))
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let dto = ManagedSpaceDTO(domain: space)
        request.httpBody = try JSONEncoder().encode(dto)
        let (_, response) = try await session.data(for: request)
        try ensureSuccess(response: response, data: nil)
    }

    func uploadPhoto(data: Data, filename: String, spaceId: String) async throws -> URL {
        throw NSError(domain: "Upload not implemented", code: -1)
    }

    func deletePhoto(url: URL, spaceId: String) async throws {
        throw NSError(domain: "Delete not implemented", code: -1)
    }

    func saveFacilities(spaceId: String, facilityIDs: [String]) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/spaces/\(spaceId)/facilities"))
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = ["facilityIDs": facilityIDs]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try ensureSuccess(response: response, data: nil)
    }

    func saveAvailability(spaceId: String, weekdays: Set<Int>) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/spaces/\(spaceId)/availability"))
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = ["weekdays": Array(weekdays)]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try ensureSuccess(response: response, data: nil)
    }

    func saveRules(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/spaces/\(spaceId)/rules"))
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = ["minDurationMinutes": minDurationMinutes, "bufferMinutes": bufferMinutes]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try ensureSuccess(response: response, data: nil)
    }

    func updateFlags(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/spaces/\(spaceId)/flags"))
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authTokenProvider() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body = ["isEnabled": isEnabled, "autoApprove": autoApprove]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, response) = try await session.data(for: request)
        try ensureSuccess(response: response, data: nil)
    }

    func fetchFacilities() async throws -> [Facility] {
        // Endpoint /facilities does not exist. returning static list.
        let staticList = [
            "Wi-Fi", "Ar condicionado", "Estacionamento", "Café", 
            "Sala de reunião", "Acessibilidade", "Água filtrada", 
            "Armário", "Impressora", "Copa", "Banheiro", 
            "Recepção", "Segurança 24h"
        ]
        return staticList.map { name in
            Facility(id: name, name: name, systemImage: "star") // Using placeholder icon
        }
    }

    func saveAll(
        space: ManagedSpace,
        facilityIDs: [String],
        weekdays: Set<Int>,
        minDurationMinutes: Int,
        bufferMinutes: Int,
        autoApprove: Bool,
        rules: String,
        startTime: String?,
        endTime: String?
    ) async throws {
        // Safe URL construction
        let fullURL = baseURL.appendingPathComponent("spaces").appendingPathComponent("full")
        var request = URLRequest(url: fullURL)
        
        // Detailed Logging
        print("➡️ SaveAll PUT URL:", fullURL.absoluteString)
        
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let token = authTokenProvider()
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 Auth Token Present: YES")
        } else {
            print("⚠️ Auth Token Present: NO (Provider returned nil)")
        }
        
        print("📦 Headers:", request.allHTTPHeaderFields ?? [:])
        
        let payload = SpaceAggregatedUpdateDTO(
            id: space.id,
            title: space.title,
            capacity: space.capacity,
            pricePerHour: space.pricePerHour,
            description: space.description,
            isEnabled: space.isEnabled,
            autoApprove: autoApprove,
            facilityIDs: facilityIDs,
            weekdays: Array(weekdays),
            minDurationMinutes: minDurationMinutes,
            bufferMinutes: bufferMinutes,
            regras: rules,
            horaInicio: startTime,
            horaFim: endTime
        )
        
        let bodyData = try JSONEncoder().encode(payload)
        request.httpBody = bodyData
        print("📦 Body Size: \(bodyData.count) bytes")
        
        let (data, response) = try await session.data(for: request)
        
        if let http = response as? HTTPURLResponse {
            print("🌐 Response Status:", http.statusCode)
            // print("🌐 Response Headers:", http.allHeaderFields) // Opcional, para reduzir ruído
        }
        
        // Log do corpo de erro se houver
        if !data.isEmpty {
             print("❌ Server Response Body:", String(data: data, encoding: .utf8) ?? "Unable to decode")
        }
        
        try ensureSuccess(response: response, data: data)
    }

    private func ensureSuccess(response: URLResponse, data: Data?) throws {
        guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        guard 200..<300 ~= http.statusCode else {
            let bodyText = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
            print("❌ HTTP", http.statusCode, "Body:", bodyText)
            throw URLError(.badServerResponse)
        }
    }
}

