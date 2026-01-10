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
    let hoster: String?
    let horaInicio: String?
    let horaFim: String?
    let diasSemana: [String]?
    let isFullDay: Bool?

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
        case hoster
        case horaInicio
        case horaFim
        case diasSemana
        case isFullDay = "diaInteiro"
    }
    func toDomain() -> CoworkingSpace {
        let address = CoworkingAddress(
            street: street,
            number: number,
            complement: complement,
            district: bairro,
            city: cidade,
            state: state,
            country: country
        )
        let pricing = CoworkingPricing(
            hourlyRate: precoHora,
            dailyRate: precoDia,
            isFullDay: isFullDay ?? false
        )
        let availability = CoworkingAvailability(
            startHour: horaInicio,
            endHour: horaFim,
            weekdays: diasSemana
        )
        return CoworkingSpace(
            id: id,
            name: nome,
            description: descricao,
            category: categoria,
            subcategory: subcategoria,
            imageUrl: imagemUrl,
            address: address,
            pricing: pricing,
            availability: availability,
            facilities: facilities,
            rules: regras,
            hosterId: hoster
        )
    }
}
