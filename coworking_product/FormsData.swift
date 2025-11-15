import Foundation

class FormData: ObservableObject {
    @Published var nome = ""
    @Published var email = ""
    @Published var ddd = ""
    @Published var numeroTelefone = ""
    @Published var cpf = ""
    @Published var cnpj = ""
    @Published var erroCPF = false
    @Published var erroCNPJ = false
    @Published var erroEmail = false
    @Published var razaoSocial = ""
    @Published var enderecoRua = ""
    @Published var numero = ""
    @Published var complemento = ""
    @Published var bairro = ""
    @Published var cidade = ""
    @Published var estado = "SP"
    @Published var nomeEspaco = ""
    @Published var capacidadePessoas = ""
    @Published var categoria = "Escritório e Negócios"
    @Published var subcategoria = "Escritório privativo"
    @Published var descricaoEspaco = ""
    @Published var regras = ""
    @Published var facilidadesSelecionadas: Set<String> = []
    @Published var diasDisponiveis: Set<String> = []
    @Published var horarioInicio: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    @Published var horarioFim: Date = {
        var components = DateComponents()
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @Published var precoPorHora = ""
    @Published var precoPorDia = ""
    @Published var imagemUrl: String? = nil
    
    func setCategoria(_ cat: String) {
        categoria = cat
        subcategoria = FormsConstants.categorias[cat]?.first ?? ""
    }
}
