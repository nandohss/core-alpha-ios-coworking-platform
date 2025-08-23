struct Coworking: Identifiable, Decodable {
    let id: String
    let nome: String
    let cidade: String
    let bairro: String
    let imagemUrl: String?
    let precoHora: Double
    let precoDia: Double?
    let descricao: String
    let categoria: String
    let subcategoria: String
    let facilities: [String]

    enum CodingKeys: String, CodingKey {
        case id = "spaceId"
        case nome = "name"
        case cidade = "city"
        case bairro = "district"
        case imagemUrl
        case precoHora
        case precoDia
        case descricao
        case categoria
        case subcategoria
        case facilities = "amenities"
    }
}
