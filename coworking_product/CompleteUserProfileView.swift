import SwiftUI

enum UserProfileField: Hashable {
    case cpf, rg
}

// MARK: - Flow Layout (iOS 16+)
struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: maxWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            view.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Interest grid
struct InterestTagGrid: View {
    let tags: [String]
    @Binding var selected: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Você busca espaços de qual vertical? Selecione as opções que deseja")
                .font(.caption)
                .foregroundColor(.gray)

            TagFlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    tagView(tag)
                }
            }
        }
    }

    private func tagView(_ text: String) -> some View {
        let isOn = selected.contains(text)
        return Button {
            if isOn { selected.remove(text) } else { selected.insert(text) }
        } label: {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isOn ? Color.black : Color.gray.opacity(0.15))
                .foregroundColor(isOn ? .white : .black)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - UI Helpers
struct SimpleSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            content
        }
        .padding(16)
        .background(Color.gray.opacity(0.07))
        .cornerRadius(12)
    }
}

struct SimpleTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.gray)
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .textFieldStyle(.roundedBorder)
        }
    }
}

// MARK: - Validators
private func onlyDigits(_ s: String) -> String { s.filter(\.isNumber) }

private func isValidCPF(_ s: String) -> Bool {
    let digits = onlyDigits(s)
    return digits.count == 11
}

private func isValidRG(_ s: String) -> Bool {
    let digits = onlyDigits(s)
    return (5...12).contains(digits.count)
}

// MARK: - ViewModel
final class CompleteUserProfileData: ObservableObject {
    @Published var cpf: String = ""
    @Published var rg: String = ""
    @Published var language: String = "Português (Brasil)"
    @Published var currency: String = "BRL"
    @Published var interests: Set<String> = []
    @Published var acceptedTerms: Bool = false

    // Errors
    @Published var cpfError: Bool = false
    @Published var rgError: Bool = false
    @Published var termsError: Bool = false
}

// MARK: - Main View
struct CompleteUserProfileView: View {
    @Binding var isPresented: Bool
    @StateObject private var data = CompleteUserProfileData()
    @FocusState private var focused: UserProfileField?

    private let interestOptions = [
        "Escritório e Negócios",
        "Beleza e Estética",
        "Saúde e Bem-estar",
        "imagem e Produção",
        "Educação e Sociais",
        "Moda e Design",
        "Tecnologia e Criatividade"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    SimpleSection(title: "Dados pessoais") {
                        SimpleTextField(title: "CPF", text: $data.cpf, keyboard: .numberPad)
                            .onChange(of: data.cpf) { newValue in
                                data.cpf = String(onlyDigits(newValue).prefix(11))
                            }
                            .focused($focused, equals: .cpf)

                        if data.cpfError {
                            Text("CPF inválido")
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        SimpleTextField(title: "RG", text: $data.rg, keyboard: .numberPad)
                            .onChange(of: data.rg) { newValue in
                                data.rg = String(onlyDigits(newValue).prefix(12))
                            }
                            .focused($focused, equals: .rg)

                        if data.rgError {
                            Text("RG inválido")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    SimpleSection(title: "Interesses") {
                        InterestTagGrid(tags: interestOptions, selected: $data.interests)
                            .padding(.top, 4)
                    }

                    SimpleSection(title: "Aceite") {
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $data.acceptedTerms) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("Li e aceito os ")
                                    Link("Termos de Uso", destination: URL(string: "https://example.com/termos")!)
                                    Text(" e a ")
                                    Link("Política de Privacidade", destination: URL(string: "https://example.com/privacidade")!)
                                }
                            }
                            .tint(.black)

                            if data.termsError {
                                Text("Você precisa aceitar os termos para continuar.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Completar cadastro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { isPresented = false } label: { Image(systemName: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!isValid())
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") {
                        focused = nil
                    }
                    .foregroundStyle(.black)
                }
            }
        }
    }

    private func isValid() -> Bool {
        !data.cpf.isEmpty && isValidCPF(data.cpf) &&
        !data.rg.isEmpty && isValidRG(data.rg) &&
        !data.interests.isEmpty &&
        data.acceptedTerms
    }

    private func save() {
        data.cpfError = !isValidCPF(data.cpf)
        data.rgError = !isValidRG(data.rg)
        data.termsError = !data.acceptedTerms
        guard isValid() else { return }

        // TODO: Integrate with your persistence/API layer
        isPresented = false
    }
}

#Preview {
    CompleteUserProfileView(isPresented: .constant(true))
}
