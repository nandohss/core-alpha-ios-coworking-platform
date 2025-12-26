import SwiftUI
import Foundation

// Uses CoHosterReservationsVM, SpaceSectionViewData and ReservationRowViewData defined in Presentation layer.

struct CoHosterReservationsView: View {
    // MARK: - State (mock — troque pelo loader real/Amplify)
    @State private var searchText: String = ""
    @State private var statusFilter: CoHosterReservationStatus? = nil
    @StateObject private var viewModel = CoHosterReservationsVM()

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
                    Button("Pendente")   { statusFilter = .pending }
                    Button("Confirmada") { statusFilter = .confirmed }
                    Button("Cancelada")  { statusFilter = .canceled }
                    Button("Recusada")   { statusFilter = .refused }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .foregroundColor(.gray)
                }
                .contentTransition(.opacity)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .overlay(Divider(), alignment: .bottom)

            // ===== Lista (sempre presente) + Empty State em overlay =====
            List {
                if !viewModel.sections.isEmpty {
                    ForEach(viewModel.sections) { section in
                        Section {
                            ForEach(section.items) { r in
                                NavigationLink {
                                    CoHosterReservationDetailView(
                                        reservation: r.detail,
                                        approveAction: { _ in },
                                        rejectAction: { _ in },
                                        cancelAction: { _ in }
                                    )
                                } label: {
                                    ReservationRow(
                                        row: r,
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
                if viewModel.sections.isEmpty {
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
            .animation(.easeInOut(duration: 0.2), value: viewModel.sections.count)
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
            await viewModel.load(hosterId: coHosterId, status: statusFilter, search: searchText)
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
    let row: ReservationRowViewData
    let greenPrimary: Color
    let grayPrimary: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Data “avatar”
            VStack {
                Text(row.dayText)
                    .font(.system(size: 20, weight: .bold))
                Text(row.monthText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 52, height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(row.guestTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusChip(
                        status: row.status,
                        greenPrimary: greenPrimary,
                        grayPrimary: grayPrimary
                    )
                }
                Text(row.rangeText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Chip de Status (estética igual a “Disponível/Ocupado”)
private struct StatusChip: View {
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

fileprivate func mapStatus(_ status: CoHosterReservationStatus) -> CoHosterReservationViewData.Status {
    switch status {
    case .pending:   return .pending
    case .confirmed: return .approved
    case .refused:   return .rejected
    case .canceled:  return .cancelled
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

