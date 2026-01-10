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
    let details: [CoHosterReservationViewData]
}

// MARK: - Formatting Service
protocol ReservationFormatting {
    func day(_ date: Date) -> String
    func month(_ date: Date) -> String
    func range(start: Date, end: Date) -> String
}

struct DefaultReservationFormatting: ReservationFormatting {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
        return cal
    }()
    
    private let dayDF: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d"
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        return df
    }()
    
    private let monthDF: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM"
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        df.locale = Locale(identifier: "pt_BR")
        return df
    }()
    
    private let dateDF: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        df.locale = Locale(identifier: "pt_BR")
        return df
    }()
    
    private let timeDF: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        df.timeZone = TimeZone(identifier: "America/Sao_Paulo")
        return df
    }()

    func day(_ date: Date) -> String { dayDF.string(from: date) }
    func month(_ date: Date) -> String { monthDF.string(from: date).uppercased() }
    func range(start: Date, end: Date) -> String {
        if calendar.isDate(start, inSameDayAs: end) {
            return "\(timeDF.string(from: start)) — \(timeDF.string(from: end))"
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

        // 1. Agrupar por Space
        let groupsBySpace = Dictionary(grouping: filtered, by: { $0.spaceId })
        
        let braCal: Calendar = {
            var c = Calendar(identifier: .gregorian)
            c.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .current
            return c
        }()
        
        // 2. Mapear cada grupo de espaço
        let sections: [SpaceSectionViewData] = groupsBySpace.compactMap { (spaceId, items) in
            let name = items.first?.spaceName ?? "—"
            
            // 3. Agrupar por (userId, dia, status)
            let groupedItems = Dictionary(grouping: items) { item -> String in
                // Use dateReservation provided by backend if available, otherwise fallback to local calculation
                let dateKey = item.dateReservation ?? braCal.startOfDay(for: item.start).description
                return "\(item.userId)|\(dateKey)|\(item.status)"
            }
            
            // 4. Criar Rows a partir dos grupos
            let rows: [ReservationRowViewData] = groupedItems.compactMap { (_, groupItems) in
                guard let first = groupItems.first else { return nil }
                
                // Ordenar por horário dentro do grupo
                let sortedGroup = groupItems.sorted { $0.start < $1.start }
                
                // Formatar range: mostrar lista de horas
                let timeStrings = sortedGroup.map { item in
                    let f = DateFormatter()
                    f.dateFormat = "HH:mm"
                    f.timeZone = TimeZone(identifier: "America/Sao_Paulo")
                    return f.string(from: item.start)
                }.joined(separator: ", ")
                
                let guest = first.userName ?? first.userEmail ?? first.userId
                
                // Mapear detalhes
                let detailsList = sortedGroup.map { item in
                    CoHosterReservationViewData(
                        id: item.id,
                        spaceId: item.spaceId,
                        code: item.id,
                        spaceName: name,
                        roomLabel: nil, 
                        capacity: item.capacity ?? 0,
                        startDate: item.start,
                        endDate: item.end,
                        createdAt: item.createdAt ?? item.start,
                        total: item.totalValue ?? 0,
                        dailyRate: item.dailyRate,
                        isFullDay: item.isFullDay ?? false,
                        status: mapStatus(item.status),
                        guestName: guest,
                        guestEmail: item.userEmail ?? "",
                        guestPhone: nil,
                        cpf: nil,
                        cnpj: nil
                    )
                }
                
                return ReservationRowViewData(
                    id: first.id, // ID representativo
                    guestTitle: guest,
                    dayText: formatter.day(first.start),
                    monthText: formatter.month(first.start),
                    rangeText: timeStrings, // Agora mostra lista de horários
                    status: first.status,
                    details: detailsList
                )
            }
            // Ordenar rows por data visual
            .sorted { 
                 $0.details.first?.startDate ?? Date() < $1.details.first?.startDate ?? Date()
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
