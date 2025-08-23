// ComponentsFormModular.swift
// Arquivo separado para os componentes reutilizáveis do BecomeCoHosterView

import SwiftUI

// MARK: - Botão de Navegação
struct NavBtnStyle: ButtonStyle {
    let background: Color
    let foreground: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(background)
            .foregroundColor(foreground)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Campo de Texto
struct CustomField: View {
    var title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var width: CGFloat? = nil
    var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(title, text: $text)
                .keyboardType(keyboard)
                .padding()
                .background(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(error != nil ? Color.red : Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
                .frame(maxWidth: width ?? .infinity)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}


// MARK: - Label de Campo
struct FieldLabel: View {
    var label: String
    var value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.gray)
            Spacer()
            Text(value)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Campo com contador de caracteres
struct TextoContado: View {
    var title: String
    @Binding var text: String
    var limit: ClosedRange<Int>
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption).foregroundColor(.gray)
                Spacer()
                Text("\(text.count)/\(limit.upperBound)")
                    .font(.caption2)
                    .foregroundColor(text.count >= limit.lowerBound ? .green : .gray)
            }
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .onChange(of: text) { _ in
                    if text.count > limit.upperBound {
                        text = String(text.prefix(limit.upperBound))
                    }
                }
        }
    }
}

// MARK: - Campo de Moeda
struct CurrencyField: View {
    var title: String
    @Binding var value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundColor(.gray)
            TextField("R$ 0,00", text: $value)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .onChange(of: value) { v in
                    value = mascaraBRL(v)
                }
        }
    }
    private func mascaraBRL(_ s: String) -> String {
        let nums = s.filter { $0.isNumber }
        let cents = Double(nums) ?? 0
        let value = cents / 100
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        f.currencySymbol = "R$ "
        return f.string(from: NSNumber(value: value)) ?? s
    }
}

// MARK: - Grade de Tags
struct TagGrid: View {
    let tags: [String]
    @Binding var selected: Set<String>
    private let cols = [GridItem(.adaptive(minimum: 120), spacing: 12)]
    var body: some View {
        LazyVGrid(columns: cols, spacing: 12) {
            ForEach(tags, id: \ .self) { tag in
                Button {
                    if selected.contains(tag) {
                        selected.remove(tag)
                    } else {
                        selected.insert(tag)
                    }
                } label: {
                    Text(tag)
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(selected.contains(tag) ? Color.black : Color.gray.opacity(0.2))
                        .foregroundColor(selected.contains(tag) ? .white : .black)
                        .cornerRadius(18)
                }
            }
        }
    }
}

// MARK: - Disponibilidade Inline
struct DisponibilidadeInline: View {
    @Binding var dias: Set<String>
    @Binding var inicio: Date
    @Binding var fim: Date
    private let todos = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dias da semana").font(.caption).foregroundColor(.gray)
            TagGrid(tags: todos, selected: $dias)
            DatePicker("Início", selection: $inicio, displayedComponents: .hourAndMinute)
            DatePicker("Fim", selection: $fim, displayedComponents: .hourAndMinute)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Seção com título
struct SectionView<Content: View>: View {
    var title: String
    var content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(.headline)
            content
        }
        .padding(.horizontal)
    }
}

// MARK: - Funções auxiliares
func formatarTelefone(_ nums: String) -> String {
    guard nums.count > 4 else { return nums }
    let part1 = nums.prefix(nums.count - 4)
    let part2 = nums.suffix(4)
    return "\(part1)-\(part2)"
}
