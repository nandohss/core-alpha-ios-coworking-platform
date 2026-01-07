import SwiftUI
import UIKit
import Amplify

// Enum global compartilhada por todo o app
enum SpaceFormField: Hashable {
    case email, ddd, telefone
    case cnpj, razaoSocial
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
                                                    formData.imagemUrl = url
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
                .dismissKeyboardOnTap()
            }
            .sheet(isPresented: $mostrarImagePicker) {
                ImagePicker(image: $imagemSelecionada)
            }
            .onChange(of: imagemSelecionada) { newImage in
                if let img = newImage {
                    imagemSelecionada = cropToSquare(img)
                }
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
        SectionView(title: "Informações básicas") {
            CustomField(title: "CNPJ (opcional)", text: $formData.cnpj, keyboard: .numberPad, error: formData.erroCNPJ ? "CNPJ inválido" : nil)
                .onChange(of: formData.cnpj) { newValue in
                    formData.cnpj = String(newValue.filter(\.isNumber).prefix(14))
                }
                .focused($focusedField, equals: .cnpj)
                .id(SpaceFormField.cnpj)

            CustomField(title: "E‑mail corporativo", text: $formData.email, keyboard: .emailAddress, error: formData.erroEmail ? "E-mail inválido" : nil)
                .onChange(of: formData.email) { newValue in
                    formData.email = newValue
                }
                .focused($focusedField, equals: .email)
                .id(SpaceFormField.email)

            CustomField(title: "Razão Social (opcional)", text: $formData.razaoSocial)
                .focused($focusedField, equals: .razaoSocial)
                .id(SpaceFormField.razaoSocial)

            HStack(spacing: 10) {
                CustomField(title: "DDD", text: $formData.ddd, keyboard: .numberPad, width: 80)
                    .onChange(of: formData.ddd) { v in
                        formData.ddd = String(v.filter { $0.isNumber }.prefix(2))
                    }
                    .focused($focusedField, equals: .ddd)
                    .id(SpaceFormField.ddd)

                CustomField(title: "Telefone", text: $formData.numeroTelefone, keyboard: .numberPad)
                    .onChange(of: formData.numeroTelefone) { v in
                        formData.numeroTelefone = formatarTelefone(v.filter { $0.isNumber })
                    }
                    .focused($focusedField, equals: .telefone)
                    .id(SpaceFormField.telefone)
            }
        }
    }

    private var etapaEndereco: some View {
        SectionView(title: "Endereço") {
            CustomField(title: "Rua", text: $formData.enderecoRua)
                .focused($focusedField, equals: .rua)
                .id(SpaceFormField.rua)

            HStack {
                CustomField(title: "Número", text: $formData.numero, keyboard: .numberPad, width: 120)
                    .focused($focusedField, equals: .numero)
                    .id(SpaceFormField.numero)
                CustomField(title: "Complemento", text: $formData.complemento)
                    .focused($focusedField, equals: .complemento)
                    .id(SpaceFormField.complemento)
            }

            CustomField(title: "Bairro", text: $formData.bairro)
                .focused($focusedField, equals: .bairro)
                .id(SpaceFormField.bairro)

            HStack {
                CustomField(title: "Cidade", text: $formData.cidade)
                    .focused($focusedField, equals: .cidade)
                    .id(SpaceFormField.cidade)

                Menu {
                    ForEach(FormsConstants.ufs, id: \.self) { uf in
                        Button(uf) { formData.estado = uf }
                    }
                } label: {
                    FieldLabel(label: "Estado", value: formData.estado)
                }
                .frame(width: 100)
            }
        }
    }

    private var etapaDetalhesEspaco: some View {
        SectionView(title: "Detalhes do espaço") {
            CustomField(title: "Nome do espaço", text: $formData.nomeEspaco)
                .focused($focusedField, equals: .nomeEspaco)
                .id(SpaceFormField.nomeEspaco)

            CustomField(title: "Capacidade (pessoas)", text: $formData.capacidadePessoas, keyboard: .numberPad)
                .focused($focusedField, equals: .capacidade)
                .id(SpaceFormField.capacidade)

            Menu {
                ForEach(FormsConstants.categorias.keys.sorted(), id: \.self) { cat in
                    Button(cat) { formData.setCategoria(cat) }
                }
            } label: {
                FieldLabel(label: "Categoria", value: formData.categoria)
            }

            Menu {
                ForEach(FormsConstants.categorias[formData.categoria] ?? [], id: \.self) { sub in
                    Button(sub) { formData.subcategoria = sub }
                }
            } label: {
                FieldLabel(label: "Subcategoria", value: formData.subcategoria)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Imagem do espaço").font(.caption).foregroundColor(.gray)

                ZStack {
                    if let imagem = imagemSelecionada {
                        Image(uiImage: imagem)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 180)
                            .overlay(
                                Text("Nenhuma imagem selecionada")
                                    .foregroundColor(.gray)
                            )
                            .cornerRadius(10)
                    }
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
            TextoContado(title: "Descrição (mín. 50 caracteres)", text: $formData.descricaoEspaco, limit: 50...500)
                .focused($focusedField, equals: .descricao)
                .id(SpaceFormField.descricao)
                .frame(minHeight: 160)
            TextoContado(title: "Regras (mín. 20 caracteres)", text: $formData.regras, limit: 20...300)
                .focused($focusedField, equals: .regras)
                .id(SpaceFormField.regras)
                .frame(minHeight: 140)
        }
    }

    private var etapaFacilidades: some View {
        TagGrid(tags: FormsConstants.todasFacilidades, selected: $formData.facilidadesSelecionadas)
            .padding(.top, 10)
    }

    private var etapaDisponibilidadePreco: some View {
        SectionView(title: "Disponibilidade e preço") {
            DisponibilidadeInline(dias: $formData.diasDisponiveis,
                                  inicio: $formData.horarioInicio,
                                  fim: $formData.horarioFim)
            HStack {
                CurrencyField(title: "Preço por hora", value: $formData.precoPorHora)
                    .focused($focusedField, equals: .precoHora)
                    .id(SpaceFormField.precoHora)
                CurrencyField(title: "Preço por dia", value: $formData.precoPorDia)
                    .focused($focusedField, equals: .precoDia)
                    .id(SpaceFormField.precoDia)
            }
        }
    }

    // ----------- VALIDAÇÃO -----------

    private func validarCamposEtapaAtual() {
        if etapaAtual == 0 {
            formData.erroCNPJ = !formData.cnpj.isEmpty && !isCNPJValido(formData.cnpj)
            formData.erroEmail = !isEmailValido(formData.email)
        }
    }
    private func etapaValida() -> Bool {
        switch etapaAtual {
        case 0:
            return !formData.email.isEmpty && !formData.erroEmail &&
                   formData.ddd.count == 2 &&
                   formData.numeroTelefone.filter { $0.isNumber }.count >= 8
        case 1:
            return !formData.enderecoRua.isEmpty && !formData.cidade.isEmpty
        case 2:
            return !formData.capacidadePessoas.isEmpty
        case 3:
            return formData.descricaoEspaco.count >= 50 && formData.regras.count >= 20
        case 4:
            return true
        case 5:
            return !formData.diasDisponiveis.isEmpty &&
                   !formData.precoPorHora.isEmpty &&
                   !formData.precoPorDia.isEmpty
        default:
            return false
        }
    }

    private func cropToSquare(_ image: UIImage) -> UIImage {
        let originalSize = image.size
        let length = min(originalSize.width, originalSize.height)
        let originX = (originalSize.width - length) / 2.0
        let originY = (originalSize.height - length) / 2.0
        let cropRect = CGRect(x: originX, y: originY, width: length, height: length)

        guard let cgImage = image.cgImage else { return image }

        // Convert cropRect to pixel coordinates respecting image scale and orientation
        let scale = image.scale
        let pixelRect = CGRect(x: cropRect.origin.x * scale,
                               y: cropRect.origin.y * scale,
                               width: cropRect.size.width * scale,
                               height: cropRect.size.height * scale)

        guard let croppedCG = cgImage.cropping(to: pixelRect) else { return image }

        // Preserve original image scale and orientation
        return UIImage(cgImage: croppedCG, scale: image.scale, orientation: image.imageOrientation)
    }
}

// Helpers como NavBtnStyle, uploadImagemParaS3, etc. vêm depois, se necessário.


