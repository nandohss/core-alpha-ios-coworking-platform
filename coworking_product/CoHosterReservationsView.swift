import SwiftUI

struct CoHosterReservationsView: View {
    // MARK: - Models
    struct Reservation: Identifiable, Hashable {
        enum Status: String, CaseIterable {
            case confirmed = "Confirmada"
            case pending   = "Pendente"
            case canceled  = "Cancelada"
        }
        let id: UUID = .init()
        let bookingCode: String
        let spaceId: String
        let spaceName: String
        let guestName: String
        let start: Date
        let end: Date
        let total: Decimal
        let status: Status
    }

    struct SpaceSection: Identifiable, Hashable {
        let id: String          // spaceId
        let name: String        // spaceName
        let items: [Reservation]
    }

    // MARK: - State (mock — troque pelo loader real/Amplify)
    @State private var searchText: String = ""
    @State private var statusFilter: Reservation.Status? = nil
    @State private var reservations: [Reservation] = sampleData

    // MARK: - Derived
    private var filtered: [Reservation] {
        reservations.filter { r in
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = q.isEmpty
                || r.spaceName.localizedCaseInsensitiveContains(q)
                || r.guestName.localizedCaseInsensitiveContains(q)
                || r.bookingCode.localizedCaseInsensitiveContains(q)
            let matchesStatus = statusFilter == nil || r.status == statusFilter
            return matchesSearch && matchesStatus
        }
        .sorted { $0.start < $1.start }
    }

    private var grouped: [SpaceSection] {
        let byId: [String: [Reservation]] = Dictionary(grouping: filtered, by: { $0.spaceId })
        let sections: [SpaceSection] = byId.compactMap { (spaceId, items) in
            let name = items.first?.spaceName ?? "Sem nome"
            let sortedItems = items.sorted { $0.start < $1.start }
            return SpaceSection(id: spaceId, name: name, items: sortedItems)
        }
        return sections.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    // MARK: - Colors (estética do app)
    private var greenPrimary: Color { Color(red: 0, green: 0.6, blue: 0.2) } // “Disponível”
    private var grayPrimary: Color  { .gray }                                 // “Ocupado”

    var body: some View {
        VStack(spacing: 0) {

            // ===== Top Bar com BUSCA + FILTRO =====
            HStack(spacing: 10) {
                // Busca principal
                HStack {
                    Image(systemName: "magnifyingglass").opacity(0.6)
                    TextField("Buscar reservas...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill").opacity(0.5)
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

                // Filtro de status
                Menu {
                    Button("Todos") { statusFilter = nil }
                    Divider()
                    ForEach(Reservation.Status.allCases, id: \.self) { s in
                        Button(s.rawValue) { statusFilter = s }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .foregroundColor(.gray) // neutro, alinhado à app
                }
                .contentTransition(.opacity)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .bottom)

            // ===== Lista (sempre presente) + Empty State em overlay =====
            List {
                if !grouped.isEmpty {
                    ForEach(grouped) { section in
                        Section {
                            ForEach(section.items) { r in
                                ReservationRow(
                                    reservation: r,
                                    greenPrimary: greenPrimary,
                                    grayPrimary: grayPrimary
                                )
                            }
                        } header: {
                            HStack {
                                Text(section.name).font(.headline)
                                Spacer()
                                Text("\(section.items.count)")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(.tertiarySystemFill)))
                            }
                            .textCase(nil)
                        }
                    }
                } else {
                    // mantém a List viva mesmo sem itens
                    EmptyView()
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if grouped.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 34))
                            .opacity(0.6)
                        Text("Nenhuma reserva encontrada")
                            .font(.headline)
                        Text("Ajuste os filtros ou tente outro termo de busca.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                }
            }
            // evita “pular” com a abertura do teclado
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .animation(.easeInOut(duration: 0.2), value: grouped.count)
        }
    }
}

// MARK: - Row
private struct ReservationRow: View {
    let reservation: CoHosterReservationsView.Reservation
    let greenPrimary: Color
    let grayPrimary: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Data “avatar”
            VStack {
                Text(dayString(reservation.start))
                    .font(.system(size: 20, weight: .bold))
                Text(monthString(reservation.start))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 52, height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reservation.guestName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusChip(
                        status: reservation.status,
                        greenPrimary: greenPrimary,
                        grayPrimary: grayPrimary
                    )
                }
                Text("\(dateRange(reservation.start, reservation.end))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text("Código: \(reservation.bookingCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    // Helpers
    private func dayString(_ d: Date) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("d")
        return df.string(from: d)
    }
    private func monthString(_ d: Date) -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate("MMM")
        return df.string(from: d).uppercased()
    }
    private func dateRange(_ start: Date, _ end: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "\(df.string(from: start)) — \(df.string(from: end))"
    }
}

// MARK: - Chip de Status (estética igual a “Disponível/Ocupado”)
private struct StatusChip: View {
    let status: CoHosterReservationsView.Reservation.Status
    let greenPrimary: Color     // Disponível
    let grayPrimary: Color      // Ocupado

    var body: some View {
        Text(label)
            .font(.caption).bold()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(bgColor))
            .foregroundColor(fgColor)
    }

    private var label: String {
        switch status {
        case .confirmed: return "Confirmada"
        case .pending:   return "Pendente"
        case .canceled:  return "Cancelada"
        }
    }
    private var fgColor: Color {
        switch status {
        case .confirmed: return greenPrimary
        case .pending:   return grayPrimary
        case .canceled:  return .red
        }
    }
    private var bgColor: Color {
        switch status {
        case .confirmed: return greenPrimary.opacity(0.12)
        case .pending:   return grayPrimary.opacity(0.12)
        case .canceled:  return Color.red.opacity(0.12)
        }
    }
}

// MARK: - Mock (troque por seu backend)
extension CoHosterReservationsView {
    static let sampleData: [Reservation] = [
        .init(bookingCode: "BKG-1042", spaceId: "spc-1", spaceName: "Sala de Reunião A",
              guestName: "Ana Lima",
              start: Date().addingTimeInterval(3600),
              end: Date().addingTimeInterval(7200),
              total: 150, status: .confirmed),
        .init(bookingCode: "BKG-1043", spaceId: "spc-1", spaceName: "Sala de Reunião A",
              guestName: "Carlos Souza",
              start: Date().addingTimeInterval(86000),
              end: Date().addingTimeInterval(92000),
              total: 150, status: .pending),
        .init(bookingCode: "BKG-2048", spaceId: "spc-2", spaceName: "Open Workspace",
              guestName: "Mariana P.",
              start: Date().addingTimeInterval(172800),
              end: Date().addingTimeInterval(176400),
              total: 80, status: .confirmed),
        .init(bookingCode: "BKG-3099", spaceId: "spc-3", spaceName: "Auditório",
              guestName: "João Pedro",
              start: Date().addingTimeInterval(260000),
              end: Date().addingTimeInterval(268000),
              total: 500, status: .canceled)
    ]
}
