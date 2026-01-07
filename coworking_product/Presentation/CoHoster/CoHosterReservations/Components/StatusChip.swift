import SwiftUI

struct StatusChip: View {
    let status: CoHosterReservationStatus
    let greenPrimary: Color     // Disponível
    let grayPrimary: Color      // Ocupado

    var body: some View {
        Text(label)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(bgColor))
            .overlay(
                Group {
                    if case .confirmed = status {
                        Capsule().stroke(greenPrimary.opacity(0.6), lineWidth: 1)
                    }
                }
            )
            .foregroundColor(fgColor)
    }

    private var label: String {
        switch status {
        case .confirmed: return "Confirmada"
        case .pending:   return "Pendente"
        case .canceled:  return "Cancelada"
        case .refused:   return "Recusada"
        }
    }
    private var fgColor: Color {
        switch status {
        case .confirmed: return greenPrimary
        case .pending:   return .yellow
        case .canceled:  return .red
        case .refused:   return .red
        }
    }
    private var bgColor: Color {
        switch status {
        case .confirmed: return greenPrimary.opacity(0.12)
        case .pending:   return grayPrimary.opacity(0.12)
        case .canceled:  return Color.red.opacity(0.12)
        case .refused:   return Color.red.opacity(0.12)
        }
    }
}
