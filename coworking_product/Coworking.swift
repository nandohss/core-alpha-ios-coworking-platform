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
    let street: String?
    let number: String?
    let complement: String?
    let state: String?
    let country: String?
    let regras: String?
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
        case street
        case number
        case complement
        case state
        case country
        case regras
        case facilities = "amenities"
    }
}
