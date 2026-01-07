import SwiftUI

struct PriceInputField: View {
    let label: String
    @Binding var text: String
    let target: CoHosterSpaceManagementView.Field
    var focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding? = nil
    
    @State private var shouldOverwrite = false

    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Text("R$")
                    .foregroundStyle(.primary)
                    .font(.body)
                
                TextField("0,00", text: Binding(
                    get: {
                        let cleaned = text
                            .replacingOccurrences(of: "R$", with: "")
                            .replacingOccurrences(of: " ", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        return cleaned.isEmpty ? "0,00" : cleaned
                    },
                    set: { newValue in
                        let oldDigits = text.filter { "0123456789".contains($0) }
                        let newDigits = newValue.filter { "0123456789".contains($0) }
                        
                        var finalDigits = newDigits
                        
                        if shouldOverwrite {
                            // Find the new characters added
                            if newDigits.count > oldDigits.count {
                                // Simple heuristic: user typed a number, discard old state
                                // We take the difference (new chars)
                                var temp = newDigits
                                for char in oldDigits {
                                    if let index = temp.firstIndex(of: char) {
                                        temp.remove(at: index)
                                    }
                                }
                                if !temp.isEmpty {
                                    finalDigits = temp
                                }
                            }
                            shouldOverwrite = false
                        }
                        
                        if let number = Double(finalDigits) {
                            let value = number / 100.0
                            let formatted = decimalFormatter.string(from: NSNumber(value: value)) ?? "0,00"
                            text = "R$ \(formatted)"
                        } else {
                            text = ""
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .bindFocus(focus, target: target)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
            )
            // Properly bind focus
            .onAppear {
                // Ensure initialization
            }
        }
        .padding(.vertical, 4)
        // Handle focus changes manually since valid .focused() syntax for optional binding is tricky here
        // Actually, we can just use the .focused(binding, equals: value) modifier if we forward it properly.
        .onChange(of: focus?.wrappedValue) { newFocus in
            if newFocus == target {
                shouldOverwrite = true
            }
        }
    }
}

// Extension into the same file or a Utils file, but keeping it here for now if specialized
extension View {
    func bindFocus(_ focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding?, target: CoHosterSpaceManagementView.Field) -> some View {
        if let focus = focus {
            return AnyView(self.focused(focus, equals: target))
        } else {
            return AnyView(self)
        }
    }
}
