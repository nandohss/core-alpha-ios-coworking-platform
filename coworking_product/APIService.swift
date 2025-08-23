import Foundation

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
            "precoHora": form.precoPorHora.replacingOccurrences(of: "[^0-9,]", with: "", options: .regularExpression).replacingOccurrences(of: ",", with: "."),
            "precoDia": form.precoPorDia.replacingOccurrences(of: "[^0-9,]", with: "", options: .regularExpression).replacingOccurrences(of: ",", with: "."),
            "hoster": userId,
            "imagemUrl": form.imagemUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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

}
