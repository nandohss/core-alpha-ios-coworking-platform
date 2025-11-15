import SwiftUI
import UIKit
import Amplify

// Enum global compartilhada por todo o app
enum SpaceFormField: Hashable {
    case nome, email, ddd, telefone
    case cpf, cnpj, razaoSocial
    case rua, numero, complemento, bairro, cidade
    case capacidade, descricao, regras
    case precoHora, precoDia
    case nomeEspaco
}

struct AddOrEditSpaceFormView: View {
    @AppStorage("userId") var userId: String = ""
    @Binding var isPresented: Bool

    @StateObject private var formData = FormData()
    @State private var imagemSelecionada: UIImage?
    @State private var mostrarImagePicker = false
    @State private var etapaAtual = 0
    private let totalEtapas = 6

    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var focusedField: SpaceFormField?

    private var bottomInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .windows.first?.safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        // Header
                        HStack {
                            Button {
                                isPresented = false
                            } label: {
                                Image(systemName: "xmark")
                                    .foregroundColor(.black)
                                    .padding()
                                    .background(Color.black.opacity(0.05))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)

                        ProgressView(value: Double(etapaAtual + 1), total: Double(totalEtapas))
                            .progressViewStyle(.linear)
                            .tint(.black)
                            .padding(.horizontal)

                        Text("Cadastrar espaço")
                            .font(.title2.bold())
                            .padding(.bottom, 10)

                        // Etapas do formulário multipasso
                        Group {
                            switch etapaAtual {
                            case 0: etapaDadosPessoais
                            case 1: etapaEndereco
                            case 2: etapaDetalhesEspaco
                            case 3: etapaDescricaoRegras
                            case 4: etapaFacilidades
                            case 5: etapaDisponibilidadePreco
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 10)

                        // Footer com navegação
                        HStack(spacing: 20) {
                            if etapaAtual > 0 {
                                Button("Voltar") {
                                    withAnimation { etapaAtual -= 1 }
                                }
                                .buttonStyle(NavBtnStyle(background: .gray.opacity(0.2), foreground: .black))
                            }
                            Button(etapaAtual == totalEtapas - 1 ? "Finalizar" : "Próximo") {
                                validarCamposEtapaAtual()
                                if etapaValida() {
                                    if etapaAtual < totalEtapas - 1 {
                                        withAnimation { etapaAtual += 1 }
                                    } else {
                                        // Envio final...
                                        let novoId = UUID().uuidString.lowercased()
                                        if let imagem = imagemSelecionada {
                                            uploadImagemParaS3(imagem, comId: novoId) { url in
                                                DispatchQueue.main.async {
                                                    formData.midia.imagemUrl = url
                                                    APIService.enviarFormularioEspaco(formData, userId: userId, spaceId: novoId) { sucesso, erro in
                                                        DispatchQueue.main.async {
                                                            isPresented = false
                                                        }
                                                    }
                                                }
                                            }
                                        } else {
                                            APIService.enviarFormularioEspaco(formData, userId: userId, spaceId: novoId) { sucesso, erro in
                                                DispatchQueue.main.async {
                                                    isPresented = false
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .disabled(!etapaValida())
                            .buttonStyle(
                                NavBtnStyle(
                                    background: etapaValida() ? .black : .gray.opacity(0.3),
                                    foreground: .white
                                )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, max(bottomInset, 24))
                    }
                    .padding(.bottom, keyboardHeight + 16)
                    .onChange(of: focusedField) { field in
                        if let field = field {
                            // Garante rolagem fluida até o campo focado
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(field, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $mostrarImagePicker) {
                ImagePicker(image: $imagemSelecionada)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notif in
            if let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = max(0, UIScreen.main.bounds.height - frame.origin.y)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { focusedField = nil }
            }
        }
    }


    // ---------- ETAPAS ----------

    private var etapaDadosPessoais: some View {
        SectionView(title: "Seus dados") {
            CustomField(title: "Nome completo", text: $formData.hoster.nome)
                .focused($focusedField, equals: .nome)
                .id(SpaceFormField.nome)

            CustomField(title: "CPF", text: $formData.hoster.cpf, keyboard: .numberPad, error: formData.validacao.erroCPF ? "CPF inválido" : nil)
                .onChange(of: formData.hoster.cpf) { v in
                    formData.hoster.cpf = formatarCPF(v.filter { $0.isNumber })
                }
                .focused($focusedField, equals: .cpf)
                .id(SpaceFormField.cpf)

            CustomField(title: "CNPJ (opcional)", text: $formData.hoster.cnpj, keyboard: .numberPad, error: formData.validacao.erroCNPJ ? "CNPJ inválido" : nil)
                .onChange(of: formData.hoster.cnpj) { newValue in
                    formData.hoster.cnpj = String(newValue.filter(\.isNumber).prefix(14))
                }
                .focused($focusedField, equals: .cnpj)
                .id(SpaceFormField.cnpj)

            CustomField(title: "E‑mail", text: $formData.contato.email, keyboard: .emailAddress, error: formData.validacao.erroEmail ? "E-mail inválido" : nil)
                .onChange(of: formData.contato.email) { newValue in
                    formData.contato.email = newValue
                }
                .focused($focusedField, equals: .email)
                .id(SpaceFormField.email)

            CustomField(title: "Razão Social (opcional)", text: $formData.hoster.razaoSocial)
                .focused($focusedField, equals: .razaoSocial)
                .id(SpaceFormField.razaoSocial)

            HStack(spacing: 10) {
                CustomField(title: "DDD", text: $formData.contato.ddd, keyboard: .numberPad, width: 80)
                    .onChange(of: formData.contato.ddd) { v in
                        formData.contato.ddd = String(v.filter { $0.isNumber }.prefix(2))
                    }
                    .focused($focusedField, equals: .ddd)
                    .id(SpaceFormField.ddd)

                CustomField(title: "Telefone", text: $formData.contato.telefone, keyboard: .numberPad)
                    .onChange(of: formData.contato.telefone) { v in
                        formData.contato.telefone = formatarTelefone(v.filter { $0.isNumber })
                    }
                    .focused($focusedField, equals: .telefone)
                    .id(SpaceFormField.telefone)
            }
        }
    }

    private var etapaEndereco: some View {
        SectionView(title: "Endereço") {
            CustomField(title: "Rua", text: $formData.localizacao.rua)
                .focused($focusedField, equals: .rua)
                .id(SpaceFormField.rua)

            HStack {
                CustomField(title: "Número", text: $formData.localizacao.numero, keyboard: .numberPad, width: 120)
                    .focused($focusedField, equals: .numero)
                    .id(SpaceFormField.numero)
                CustomField(title: "Complemento", text: $formData.localizacao.complemento)
                    .focused($focusedField, equals: .complemento)
                    .id(SpaceFormField.complemento)
            }

            CustomField(title: "Bairro", text: $formData.localizacao.bairro)
                .focused($focusedField, equals: .bairro)
                .id(SpaceFormField.bairro)

            HStack {
                CustomField(title: "Cidade", text: $formData.localizacao.cidade)
                    .focused($focusedField, equals: .cidade)
                    .id(SpaceFormField.cidade)

                Menu {
                    ForEach(FormsConstants.ufs, id: \.self) { uf in
                        Button(uf) { formData.localizacao.estado = uf }
                    }
                } label: {
                    FieldLabel(label: "Estado", value: formData.localizacao.estado)
                }
                .frame(width: 100)
            }
        }
    }

    private var etapaDetalhesEspaco: some View {
        SectionView(title: "Detalhes do espaço") {
            CustomField(title: "Nome do espaço", text: $formData.detalhes.nome)
                .focused($focusedField, equals: .nomeEspaco)
                .id(SpaceFormField.nomeEspaco)

            CustomField(title: "Capacidade (pessoas)", text: $formData.detalhes.capacidade, keyboard: .numberPad)
                .focused($focusedField, equals: .capacidade)
                .id(SpaceFormField.capacidade)

            Menu {
                ForEach(FormsConstants.categorias.keys.sorted(), id: \.self) { cat in
                    Button(cat) { formData.setCategoria(cat) }
                }
            } label: {
                FieldLabel(label: "Categoria", value: formData.detalhes.categoria)
            }

            Menu {
                ForEach(FormsConstants.categorias[formData.detalhes.categoria] ?? [], id: \.self) { sub in
                    Button(sub) { formData.detalhes.subcategoria = sub }
                }
            } label: {
                FieldLabel(label: "Subcategoria", value: formData.detalhes.subcategoria)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Imagem do espaço").font(.caption).foregroundColor(.gray)
                if let imagem = imagemSelecionada {
                    Image(uiImage: imagem)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 160)
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 160)
                        .overlay(Text("Nenhuma imagem selecionada").foregroundColor(.gray))
                        .cornerRadius(10)
                }
                Button("Selecionar imagem") {
                    mostrarImagePicker = true
                }
                .padding(.top, 4)
            }
        }
    }

    private var etapaDescricaoRegras: some View {
        SectionView(title: "Descrição e Regras") {
            TextoContado(title: "Descrição (mín. 50 caracteres)", text: $formData.detalhes.descricao, limit: 50...500)
                .focused($focusedField, equals: .descricao)
                .id(SpaceFormField.descricao)
                .frame(minHeight: 160)
            TextoContado(title: "Regras (mín. 20 caracteres)", text: $formData.detalhes.regras, limit: 20...300)
                .focused($focusedField, equals: .regras)
                .id(SpaceFormField.regras)
                .frame(minHeight: 140)
        }
    }

    private var etapaFacilidades: some View {
        TagGrid(tags: FormsConstants.todasFacilidades, selected: $formData.facilidades.facilidades)
            .padding(.top, 10)
    }

    private var etapaDisponibilidadePreco: some View {
        SectionView(title: "Disponibilidade e preço") {
            DisponibilidadeInline(dias: $formData.disponibilidade.dias,
                                  inicio: $formData.disponibilidade.horarioInicio,
                                  fim: $formData.disponibilidade.horarioFim)
            HStack {
                CurrencyField(title: "Preço por hora", value: $formData.precos.precoPorHora)
                    .focused($focusedField, equals: .precoHora)
                    .id(SpaceFormField.precoHora)
                CurrencyField(title: "Preço por dia", value: $formData.precos.precoPorDia)
                    .focused($focusedField, equals: .precoDia)
                    .id(SpaceFormField.precoDia)
            }
        }
    }

    // ----------- VALIDAÇÃO -----------

    private func validarCamposEtapaAtual() {
        if etapaAtual == 0 {
            formData.validacao.erroCPF = !isCPFValido(formData.hoster.cpf)
            formData.validacao.erroCNPJ = !formData.hoster.cnpj.isEmpty && !isCNPJValido(formData.hoster.cnpj)
            formData.validacao.erroEmail = !isEmailValido(formData.contato.email)
        }
    }
    private func etapaValida() -> Bool {
        switch etapaAtual {
        case 0:
            return !formData.hoster.nome.isEmpty &&
                   !formData.contato.email.isEmpty && !formData.validacao.erroEmail &&
                   !formData.hoster.cpf.isEmpty && !formData.validacao.erroCPF &&
                   formData.contato.ddd.count == 2 &&
                   formData.contato.telefone.filter { $0.isNumber }.count >= 8
        case 1:
            return !formData.localizacao.rua.isEmpty && !formData.localizacao.cidade.isEmpty
        case 2:
            return !formData.detalhes.capacidade.isEmpty
        case 3:
            return formData.detalhes.descricao.count >= 50 && formData.detalhes.regras.count >= 20
        case 4:
            return true
        case 5:
            return !formData.disponibilidade.dias.isEmpty &&
                   !formData.precos.precoPorHora.isEmpty &&
                   !formData.precos.precoPorDia.isEmpty
        default:
            return false
        }
    }
}

// Helpers como NavBtnStyle, uploadImagemParaS3, etc. vêm depois, se necessário.
