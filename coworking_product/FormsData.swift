import Foundation

struct HosterInfo {
    var nome = ""
    var cpf = ""
    var cnpj = ""
    var razaoSocial = ""
}

struct ContactInfo {
    var email = ""
    var ddd = ""
    var telefone = ""
}

struct SpaceLocation {
    var rua = ""
    var numero = ""
    var complemento = ""
    var bairro = ""
    var cidade = ""
    var estado = "SP"
}

struct SpaceDetails {
    var nome = ""
    var capacidade = ""
    var categoria = "Escritório e Negócios"
    var subcategoria = "Escritório privativo"
    var descricao = ""
    var regras = ""
}

struct AmenitiesSelection {
    var facilidades: Set<String> = []
}

struct AvailabilityOptions {
    var dias: Set<String> = []
    var horarioInicio: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    var horarioFim: Date = {
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
}

struct PricingOptions {
    var precoPorHora = ""
    var precoPorDia = ""
}

struct MediaInfo {
    var imagemUrl: String? = nil
}

struct FormValidationState {
    var erroCPF = false
    var erroCNPJ = false
    var erroEmail = false
}

class FormData: ObservableObject {
    @Published var hoster = HosterInfo()
    @Published var contato = ContactInfo()
    @Published var localizacao = SpaceLocation()
    @Published var detalhes = SpaceDetails()
    @Published var facilidades = AmenitiesSelection()
    @Published var disponibilidade = AvailabilityOptions()
    @Published var precos = PricingOptions()
    @Published var midia = MediaInfo()
    @Published var validacao = FormValidationState()

    func setCategoria(_ categoria: String) {
        detalhes.categoria = categoria
        detalhes.subcategoria = FormsConstants.categorias[categoria]?.first ?? ""
    }
}

extension FormData {
    var telefoneCompleto: String {
        let numero = contato.telefone.filter { $0.isNumber }
        return "(\(contato.ddd)) \(numero)"
    }

    func limparMascaraMonetaria(_ valor: String) -> String {
        valor.replacingOccurrences(of: "[^0-9,]", with: "", options: .regularExpression)
            .replacingOccurrences(of: ",", with: ".")
    }
}
