import Foundation
import Amplify

// MARK: - Model da Reserva
struct Reserva: Encodable {
    let spaceId_reservation: String
    let date_reservation: String
    let hours_reservation: [String]
    let status: String
    let userId: String
}

struct DisponibilidadeResposta: Decodable {
    let available: Bool
    let conflicts: [String]
}

// MARK: - ViewModel
@MainActor
class ReservaViewModel: ObservableObject {
    @Published var status: String? = nil
    @Published var isSending = false
    @Published var errorMessage: String? = nil

    /// Envia reserva com userId atual
    func enviarReserva(spaceId: String, date: String, hours: [String]) async {
        isSending = true
        defer { isSending = false }

        guard let attributes = try? await Amplify.Auth.fetchUserAttributes(),
              let userId = attributes.first(where: { $0.key.rawValue == "sub" })?.value else {
            self.errorMessage = "Usuário não autenticado"
            return
        }

        let reserva = Reserva(
            spaceId_reservation: spaceId,
            date_reservation: date,
            hours_reservation: hours,
            status: "reserved",
            userId: userId
        )

        await enviarReserva(reserva)
    }
 
    /// Envia a requisição de reserva
    func enviarReserva(_ reserva: Reserva) async {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/reservations") else {
            self.errorMessage = "URL inválida"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(reserva)
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Código HTTP: \(httpResponse.statusCode)")
                if let body = String(data: data, encoding: .utf8) {
                    print("📦 Corpo da resposta: \(body)")
                }

                if httpResponse.statusCode == 200 {
                    self.status = "Reserva enviada com sucesso!"
                } else {
                    self.errorMessage = "Erro do servidor: código \(httpResponse.statusCode)"
                }
            }
        } catch {
            self.errorMessage = "Erro ao enviar reserva: \(error.localizedDescription)"
        }
    }


    /// Verifica se há conflitos de horário
    func verificarDisponibilidade(spaceId: String, date: String, hours: [String]) async -> [String] {
        guard var components = URLComponents(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/reservations") else {
            return []
        }

        let hoursJSON = String(data: try! JSONEncoder().encode(hours), encoding: .utf8)!

        components.queryItems = [
            URLQueryItem(name: "spaceId", value: spaceId),
            URLQueryItem(name: "date", value: date),
            URLQueryItem(name: "hours", value: hoursJSON)
        ]

        guard let url = components.url else { return [] }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let result = try JSONDecoder().decode(DisponibilidadeResposta.self, from: data)
                return result.conflicts
            } else {
                print("❌ Falha ao verificar disponibilidade. Código: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                return []
            }
        } catch {
            print("❌ Erro na verificação de disponibilidade: \(error.localizedDescription)")
            return []
        }
    }
}
