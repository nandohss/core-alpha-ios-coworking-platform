import SwiftUI
import Foundation

// MARK: - View Data used by the View (Presentation Layer)
struct SpaceSectionViewData: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let items: [ReservationRowViewData]
}

struct ReservationRowViewData: Identifiable, Equatable, Hashable {
    let id: String
    let guestTitle: String
    let dayText: String
    let monthText: String
    let rangeText: String
    let status: CoHosterReservationStatus
    let detail: CoHosterReservationViewData
}

// MARK: - Formatting Service
protocol ReservationFormatting {
    func day(_ date: Date) -> String
    func month(_ date: Date) -> String
    func range(start: Date, end: Date) -> String
}

struct DefaultReservationFormatting: ReservationFormatting {
    private let dayDF: DateFormatter = {
        let df = DateFormatter(); df.setLocalizedDateFormatFromTemplate("d"); return df
    }()
    private let monthDF: DateFormatter = {
        let df = DateFormatter(); df.setLocalizedDateFormatFromTemplate("MMM"); return df
    }()
    private let dateDF: DateFormatter = {
        let df = DateFormatter(); df.dateStyle = .medium; df.timeStyle = .short; return df
    }()

    func day(_ date: Date) -> String { dayDF.string(from: date) }
    func month(_ date: Date) -> String { monthDF.string(from: date).uppercased() }
    func range(start: Date, end: Date) -> String {
        if Calendar.current.isDate(start, inSameDayAs: end) {
            let t = DateFormatter(); t.dateFormat = "HH:mm"
            return "\(t.string(from: start)) — \(t.string(from: end))"
        }
        return "\(dateDF.string(from: start)) — \(dateDF.string(from: end))"
    }
}

// MARK: - ViewModel (Presentation)
@MainActor
final class CoHosterReservationsVM: ObservableObject {
    @Published var sections: [SpaceSectionViewData] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let formatter: ReservationFormatting
    private let fetchUseCase: any FetchCoHosterReservationsUseCase
    let updateUseCase: any UpdateCoHosterReservationStatusUseCase // Made internal (removed private) to share with DetailVM

    init(
        formatter: ReservationFormatting = DefaultReservationFormatting(),
        fetchUseCase: any FetchCoHosterReservationsUseCase = FetchCoHosterReservationsUseCaseImpl(repository: CoHosterReservationsRepositoryImpl()),
        updateUseCase: any UpdateCoHosterReservationStatusUseCase = UpdateCoHosterReservationStatusUseCaseImpl(repository: CoHosterReservationsRepositoryImpl())
    ) {
        self.formatter = formatter
        self.fetchUseCase = fetchUseCase
        self.updateUseCase = updateUseCase
    }

    func approve(reservation: CoHosterReservationViewData) async throws {
        try await updateUseCase.execute(id: reservation.id, spaceId: reservation.spaceId, date: reservation.startDate, status: .confirmed)
        // Refresh local state if needed, or rely on pull to refresh. 
        // Better UX: update local list immediately.
        updateLocalStatus(id: reservation.id, newStatus: .confirmed)
    }

    func reject(reservation: CoHosterReservationViewData) async throws {
        try await updateUseCase.execute(id: reservation.id, spaceId: reservation.spaceId, date: reservation.startDate, status: .refused)
        updateLocalStatus(id: reservation.id, newStatus: .refused)
    }
    
    private func updateLocalStatus(id: String, newStatus: CoHosterReservationStatus) {
       // Deep update in sections is complex because structs.
       // Easiest is to reload. Or find and replace.
       // Let's reload to be safe and consistent with backend.
       Task {
           let coHosterId = UserDefaults.standard.string(forKey: "userId") ?? ""
           await load(hosterId: coHosterId, showLoading: false)
       }
    }

    func load(hosterId: String, status: CoHosterReservationStatus? = nil, search: String = "", showLoading: Bool = true) async {
        let trimmedId = hosterId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            self.errorMessage = "ID do hoster ausente. Faça login novamente."
            self.sections = []
            return
        }
        if showLoading { isLoading = true }
        defer { if showLoading { isLoading = false } }
        do {
            let list = try await fetchUseCase.execute(hosterId: trimmedId, status: status)
            let mapped = mapToSections(list: list, search: search)
            self.sections = mapped
        } catch {
            self.errorMessage = "Erro ao carregar reservas: \(error.localizedDescription)"
            self.sections = []
        }
    }

    // MARK: - Mapping and grouping
    private func mapToSections(list: [CoHosterReservation], search: String) -> [SpaceSectionViewData] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered: [CoHosterReservation] = list.filter { r in
            let matchesSearch = q.isEmpty
                || r.spaceId.localizedCaseInsensitiveContains(q)
                || r.userId.localizedCaseInsensitiveContains(q)
                || r.id.localizedCaseInsensitiveContains(q)
                || (r.userName?.localizedCaseInsensitiveContains(q) ?? false)
                || (r.userEmail?.localizedCaseInsensitiveContains(q) ?? false)
            return matchesSearch
        }
        .sorted { $0.start < $1.start }

        let groups = Dictionary(grouping: filtered, by: { $0.spaceId })
        let sections: [SpaceSectionViewData] = groups.compactMap { (spaceId, items) in
            let name = items.first?.spaceName ?? "—"
            let sortedItems = items.sorted { $0.start < $1.start }
            let rows: [ReservationRowViewData] = sortedItems.compactMap { item in
                let guest = item.userName ?? item.userEmail ?? item.userId
                let detail = CoHosterReservationViewData(
                    id: item.id,
                    spaceId: item.spaceId,
                    code: item.id,
                    spaceName: name,
                    roomLabel: nil,
                    capacity: item.capacity ?? 0,
                    startDate: item.start,
                    endDate: item.end,
                    createdAt: item.start,
                    total: 0,
                    status: mapStatus(item.status),
                    guestName: guest,
                    guestEmail: item.userEmail ?? "",
                    guestPhone: nil,
                    cpf: nil,
                    cnpj: nil
                )
                return ReservationRowViewData(
                    id: item.id,
                    guestTitle: guest,
                    dayText: formatter.day(item.start),
                    monthText: formatter.month(item.start),
                    rangeText: formatter.range(start: item.start, end: item.end),
                    status: item.status,
                    detail: detail
                )
            }
            return SpaceSectionViewData(id: spaceId, name: name, items: rows)
        }
        return sections.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Mapping to detail status
private func mapStatus(_ status: CoHosterReservationStatus) -> CoHosterReservationViewData.Status {
    switch status {
    case .pending:   return .pending
    case .confirmed: return .approved
    case .refused:   return .rejected
    case .canceled:  return .cancelled
    }
}
