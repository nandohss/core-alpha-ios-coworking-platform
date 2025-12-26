import SwiftUI
import Foundation

@MainActor
class CoHosterReservationsViewModel: ObservableObject {
    @Published var reservations: [ReservationDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func fetchReservations(hosterId: String, status: ReservationDTO.Status? = nil) async {
        let trimmedId = hosterId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            self.errorMessage = "ID do hoster ausente. Faça login novamente."
            self.reservations = []
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        do {
            self.reservations = try await APIService.fetchCoHosterReservations(hosterId: hosterId, status: status)
        } catch {
            self.errorMessage = "Erro ao carregar reservas: \(error.localizedDescription)"
            self.reservations = []
        }
    }
}

struct CoHosterReservationsView: View {
    // MARK: - State (mock — troque pelo loader real/Amplify)
    @State private var searchText: String = ""
    @State private var statusFilter: ReservationDTO.Status? = nil
    @StateObject private var viewModel = CoHosterReservationsViewModel()

    // MARK: - Derived

    private var filtered: [ReservationDTO] {
        viewModel.reservations.filter { r in
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = q.isEmpty
                // Como ReservationDTO do APIService não tem esses campos, usamos placeholders para filtro
                || r.spaceId.localizedCaseInsensitiveContains(q)
                || r.userId.localizedCaseInsensitiveContains(q)
                || r.id.localizedCaseInsensitiveContains(q)
            let matchesStatus = statusFilter == nil || r.status == statusFilter
            return matchesSearch && matchesStatus
        }
        .sorted { $0.startDate < $1.startDate }
    }

    private struct SpaceSection: Identifiable, Equatable, Hashable {
        let id: String          // spaceId
        let name: String        // espaço não vem no DTO, placeholder ou lookup externo
        let items: [ReservationDTO]

        static func == (lhs: SpaceSection, rhs: SpaceSection) -> Bool {
            lhs.id == rhs.id && lhs.name == rhs.name && lhs.items == rhs.items
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(name)
            hasher.combine(items)
        }
    }

    private var grouped: [SpaceSection] {
        let byId: [String: [ReservationDTO]] = Dictionary(grouping: filtered, by: { $0.spaceId })
        let sections: [SpaceSection] = byId.compactMap { (spaceId, items) in
            // Como spaceName não está no DTO, usamos placeholder "—" ou espaçoId
            let name = "—" // Aqui pode-se fazer lookup se disponível
            let sortedItems = items.sorted { $0.startDate < $1.startDate }
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
                    ForEach(ReservationDTO.Status.allCases, id: \.self) { s in
                        Button(s.rawValue.capitalized) { statusFilter = s }
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
                                NavigationLink {
                                    CoHosterReservationDetailView(
                                        reservation: CoHosterReservationViewData(
                                            id: r.id,
                                            code: r.id, // sem bookingCode no DTO, usamos id
                                            spaceName: section.name,
                                            roomLabel: nil,
                                            capacity: 0,
                                            startDate: r.startDate.toDate() ?? Date(),
                                            endDate: r.endDate.toDate() ?? Date(),
                                            createdAt: r.startDate.toDate() ?? Date(),
                                            total: 0,
                                            status: mapStatus(r.status),
                                            guestName: r.userName ?? r.userEmail ?? r.userId,
                                            guestEmail: r.userEmail ?? "",
                                            guestPhone: nil,
                                            cpf: nil,
                                            cnpj: nil
                                        ),
                                        approveAction: { _ in },
                                        rejectAction: { _ in },
                                        cancelAction: { _ in }
                                    )
                                } label: {
                                    ReservationRow(
                                        reservation: r,
                                        greenPrimary: greenPrimary,
                                        grayPrimary: grayPrimary
                                    )
                                }
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
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Carregando...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .transition(.opacity)
            }
        }
        .task {
            let coHosterId = UserDefaults.standard.string(forKey: "userId") ?? ""
            await viewModel.fetchReservations(hosterId: coHosterId, status: statusFilter)
        }
        .alert("Erro", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

// MARK: - Row
private struct ReservationRow: View {
    let reservation: ReservationDTO
    let greenPrimary: Color
    let grayPrimary: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Data “avatar”
            VStack {
                if let start = reservation.startDate.toDate() {
                    Text(dayString(start))
                        .font(.system(size: 20, weight: .bold))
                    Text(monthString(start))
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("?")
                        .font(.system(size: 20, weight: .bold))
                    Text("???")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 52, height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // Como guestName não existe, usamos userId como placeholder
                    Text(reservation.userName ?? reservation.userEmail ?? reservation.userId)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusChip(
                        status: reservation.status,
                        greenPrimary: greenPrimary,
                        grayPrimary: grayPrimary
                    )
                }
                if let start = reservation.startDate.toDate(),
                   let end = reservation.endDate.toDate() {
                    Text(dateRange(start, end))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Data inválida")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

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
    let status: ReservationDTO.Status
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

// MARK: - String extension to convert ISO8601 date strings to Date
fileprivate extension String {
    func toDate() -> Date? {
        // Assuming the dates are ISO8601 formatted strings with time zone
        let isoFormatter = ISO8601DateFormatter()
        return isoFormatter.date(from: self)
    }
}

private func mapStatus(_ status: ReservationDTO.Status) -> CoHosterReservationViewData.Status {
    switch status {
    case .pending:   return .pending
    case .confirmed: return .approved
    case .refused:   return .rejected
    case .canceled:  return .cancelled
    }
}
