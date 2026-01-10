import Foundation

struct CoworkingSpaceDTO: Decodable {
    let spaceId: String
    let name: String
    let city: String
    let district: String
    let street: String?
    let number: String?
    let complement: String?
    let state: String?
    let country: String?

    let imagemUrl: String?
    let precoHora: Double?
    let precoDia: Double?
    let descricao: String?
    let categoria: String?
    let subcategoria: String?
    let regras: String?
    let amenities: [String]?
    let hoster: String?
    let horaInicio: String?
    let horaFim: String?
    let diasSemana: [String]?
    let isFullDay: Bool?

    enum CodingKeys: String, CodingKey {
        case spaceId
        case name
        case city
        case district
        case street
        case number
        case complement
        case state
        case country
        case imagemUrl
        case precoHora
        case precoDia
        case descricao
        case categoria
        case subcategoria
        case regras
        case amenities
        case hoster
        case horaInicio
        case horaFim
        case diasSemana
        case isFullDay = "diaInteiro"
    }
}
