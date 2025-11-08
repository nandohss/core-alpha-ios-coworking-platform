import Foundation

struct ReservationDTO: Decodable, Identifiable, Equatable, Hashable {
    enum Status: String, Decodable, CaseIterable {
        case pending = "PENDING"
        case confirmed = "CONFIRMED"
        case canceled = "CANCELED"
        case refused = "REFUSED"
        case reserved = "reserved" // Se o backend pode retornar assim!
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
}

class APIService {
    static func enviarFormularioEspaco(_ form: FormData, userId: String, spaceId: String, completion: @escaping (Bool, String?) -> Void){
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/spaces") else {
            completion(false, "URL inválida")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let body: [String: Any] = [
            "spaceId": spaceId,
            "name": form.nomeEspaco,
            "city": form.cidade,
            "country": "Brasil",
            "district": form.bairro,
            "capacity": Int(form.capacidadePessoas) ?? 0,
            "amenities": Array(form.facilidadesSelecionadas),
            "availability": true,
            "categoria": form.categoria,
            "subcategoria": form.subcategoria,
            "descricao": form.descricaoEspaco,
            "regras": form.regras,
            "diasSemana": Array(form.diasDisponiveis),
            "horaInicio": formatter.string(from: form.horarioInicio),
            "horaFim": formatter.string(from: form.horarioFim),
            "precoHora": form.precoPorHora.replacingOccurrences(of: "[^0-9,]", with: "", options: String.CompareOptions.regularExpression).replacingOccurrences(of: ",", with: "."),
            "precoDia": form.precoPorDia.replacingOccurrences(of: "[^0-9,]", with: "", options: String.CompareOptions.regularExpression).replacingOccurrences(of: ",", with: "."),
            "hoster": userId,
            "imagemUrl": form.imagemUrl?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON enviado para /spaces:\n\(jsonString)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, "Erro: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "Resposta inválida")
                return
            }

            if httpResponse.statusCode == 200 {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let isHoster = json["isHoster"] as? Bool {
                    UserDefaults.standard.set(isHoster, forKey: "isHoster")
                }
                completion(true, nil)
            }
            else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Erro desconhecido"
                completion(false, msg)
            }
        }.resume()
    }
    
    static func atualizarImagem(spaceId: String, imagemUrl: String) {
        // 🔐 Garante que o spaceId será seguro para uso em query string
        guard let encodedId = spaceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/spaces?spaceId=\(encodedId)") else {
            print("❌ Erro ao criar URL para atualizar imagem com spaceId:", spaceId)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["imagemUrl": imagemUrl]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        print("📤 Atualizando imagem no DynamoDB com URL:", imagemUrl)
        print("🌐 PUT para URL:", url.absoluteString)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erro na requisição PUT:", error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Resposta inválida (não é HTTPURLResponse)")
                return
            }

            if httpResponse.statusCode == 200 {
                print("✅ imagemUrl atualizada com sucesso!")
            } else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Erro desconhecido"
                print("⚠️ Falha ao atualizar imagem: HTTP \(httpResponse.statusCode) - \(msg)")
            }
        }.resume()
    }

    // Reservas para Co-Hoster (Estratégia B: GET /reservations?coHosterId=...&status=...)
    static func fetchCoHosterReservations(hosterId: String, status: ReservationDTO.Status? = nil) async throws -> [ReservationDTO] {
        let base = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro")!
        var components = URLComponents(url: base.appendingPathComponent("reservations"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [URLQueryItem(name: "hosterId", value: hosterId)]
        if let status { items.append(URLQueryItem(name: "status", value: status.rawValue)) }
        components.queryItems = items
        guard let url = components.url else {
            throw NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Adicione headers de autenticação se necessário
        // request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "APIService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"]) }

        switch http.statusCode {
        case 200:
            return try JSONDecoder().decode([ReservationDTO].self, from: data)
        case 404:
            // Trate 404 como lista vazia se o backend usar 404 para "sem resultados"
            return []
        default:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NSError(domain: "APIService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: "Erro \(http.statusCode): \(body)"])
        }
    }
}

// MARK: - Modelos da API
struct SpaceDTO: Decodable, Identifiable {
    var id: String { spaceId }

    let spaceId: String
    let name: String
    let city: String?
    let country: String?
    let district: String?
    let capacity: Int?
    let amenities: [String]?
    let availability: Bool?
    let categoria: String?
    let subcategoria: String?
    let descricao: String?
    let regras: String?
    let diasSemana: [String]?
    let horaInicio: String?
    let horaFim: String?
    let precoHora: Double?   // ← era String?
    let precoDia: Double?    // ← era String?
    let hoster: String
    let imagemUrl: String?
}

// Se precisar apresentar:
extension SpaceDTO {
    var precoHoraFormatado: String {
        guard let v = precoHora else { return "—" }
        return NumberFormatter.currencyBR.string(from: NSNumber(value: v)) ?? "R$ \(v)"
    }
    var precoDiaFormatado: String {
        guard let v = precoDia else { return "—" }
        return NumberFormatter.currencyBR.string(from: NSNumber(value: v)) ?? "R$ \(v)"
    }
}

extension NumberFormatter {
    static let currencyBR: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()
}


// Caso a API retorne um envelope { items: [...] } use esse:
struct SpaceListEnvelope: Decodable {
    let items: [SpaceDTO]
}

extension APIService {

    /// Lista os espaços cadastrados por um hoster (userId).
    static func listarEspacosDoHoster(userId: String, completion: @escaping (Result<[SpaceDTO], Error>) -> Void) {
        // preferir path /spaces/hoster/{userId}
        let base = "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro"
        let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? userId
        let primaryURL = URL(string: "\(base)/spaces/hoster/\(encoded)")!
        var request = URLRequest(url: primaryURL)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            // fallback para query ?hoster=... se a rota ainda não estiver publicada
            if let http = response as? HTTPURLResponse, http.statusCode == 400 || http.statusCode == 404 {
                let query = URL(string: "\(base)/spaces?hoster=\(encoded)")!
                var req2 = URLRequest(url: query)
                req2.httpMethod = "GET"
                URLSession.shared.dataTask(with: req2) { data, response, error in
                    Self.decodeSpaces(data: data, response: response, error: error, completion: completion)
                }.resume()
                return
            }
            Self.decodeSpaces(data: data, response: response, error: error, completion: completion)
        }.resume()
    }

    private static func decodeSpaces(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<[SpaceDTO], Error>) -> Void) {
        if let error = error { return completion(.failure(error)) }
        guard let http = response as? HTTPURLResponse, let data = data else {
            return completion(.failure(NSError(domain: "API", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"])))
        }
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Erro \(http.statusCode)"
            return completion(.failure(NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
        }
        do {
            if let list = try? JSONDecoder().decode([SpaceDTO].self, from: data) {
                completion(.success(list))
            } else {
                let envelope = try JSONDecoder().decode(SpaceListEnvelope.self, from: data)
                completion(.success(envelope.items))
            }
        } catch {
            completion(.failure(error))
        }
    }


    /// Exclui um espaço pelo `spaceId`.
    static func deletarEspaco(spaceId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            let encoded = spaceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/spaces?spaceId=\(encoded)")
        else {
            completion(.failure(NSError(domain: "API", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            guard let http = response as? HTTPURLResponse else {
                return completion(.failure(NSError(domain: "API", code: -2, userInfo: [NSLocalizedDescriptionKey: "Resposta inválida"])))
            }
            guard (200...299).contains(http.statusCode) else {
                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Erro \(http.statusCode)"
                return completion(.failure(NSError(domain: "API", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])))
            }
            completion(.success(()))
        }.resume()
    }
}

