import SwiftUI
import Combine

// Dependências do projeto (assumindo que o projeto compila com esses nomes implícitos ou imports globais,
// caso contrário, precisaria importar os módulos específicos se fosse framework separado)

@MainActor
class MyReservationsViewModel: ObservableObject {
    @Published var reservas: [CoworkerReservation] = []
    @Published var coworkings: [String: CoworkingInfo] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Filtro de status
    @Published var statusFilter: CoworkerReservation.ReservationStatus? = nil

    private let fetchReservationsUseCase: FetchCoworkerReservationsUseCase

    // Initializer com injeção de dependência
    init(fetchReservationsUseCase: FetchCoworkerReservationsUseCase = RealFetchCoworkerReservationsUseCase(repository: CoworkerReservationsRepositoryImpl())) {
        self.fetchReservationsUseCase = fetchReservationsUseCase
    }

    // Lógica de Seções
    enum SectionType: String, Identifiable {
        case upcoming = "Próximas"
        case history = "Histórico"
        var id: String { rawValue }
    }
    
    struct ReservationGroup: Identifiable {
        let id: String
        let date: Date
        let coworking: CoworkingInfo?
        let items: [CoworkerReservation]
    }
    
    struct ReservationSection: Identifiable {
        let type: SectionType
        let items: [ReservationGroup]
        var id: String { type.rawValue }
    }
    
    var sections: [ReservationSection] {
        // 1. Filtrar por status
        let filtered = reservas.filter { r in
            guard let filter = statusFilter else { return true }
            return r.statusEnum == filter
        }
        
        // 2. Separar por data (Hoje/Futuro vs Passado)
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        
        // Formatter robusto
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone.current
        
        var upcomingRaw: [CoworkerReservation] = []
        var historyRaw: [CoworkerReservation] = []
        
        for reservation in filtered {
            if let date = dateFormatter.date(from: reservation.dateReservation) {
                if date >= todayStart {
                    upcomingRaw.append(reservation)
                } else {
                    historyRaw.append(reservation)
                }
            } else {
                // Falha no parse: tratar como histórico (antigo/inválido)
                historyRaw.append(reservation)
            }
        }
        
        // 3. Agrupar (Space + Date)
        func groupReservations(_ raw: [CoworkerReservation]) -> [ReservationGroup] {
            let groupedDict = Dictionary(grouping: raw) { "\($0.spaceId)_\($0.dateReservation)" }
            
            return groupedDict.compactMap { (key, reservations) -> ReservationGroup? in
                guard let first = reservations.first else { return nil }
                // Tenta parsear data para ordenação
                let date = dateFormatter.date(from: first.dateReservation) ?? Date.distantPast
                let coworking = coworkings[first.spaceId]
                
                // Ordenar itens internos por hora (Crescente: 09:00 -> 18:00)
                let sortedItems = reservations.sorted {
                    ($0.hourReservation) < ($1.hourReservation)
                }
                
                return ReservationGroup(id: key, date: date, coworking: coworking, items: sortedItems)
            }
        }
        
        var upcomingGroups = groupReservations(upcomingRaw)
        // Próximas: Data Crescente (Mais próxima primeiro)
        upcomingGroups.sort {
            if $0.date == $1.date { return $0.id < $1.id }
            return $0.date < $1.date
        }
        
        var historyGroups = groupReservations(historyRaw)
        // Histórico: Data Decrescente (Mais recente primeiro)
        historyGroups.sort {
            if $0.date == $1.date { return $0.id < $1.id }
            return $0.date > $1.date
        }
        
        var result: [ReservationSection] = []
        if !upcomingGroups.isEmpty { result.append(ReservationSection(type: .upcoming, items: upcomingGroups)) }
        if !historyGroups.isEmpty { result.append(ReservationSection(type: .history, items: historyGroups)) }
        
        return result
    }

    func carregarReservas(userId: String) async {
        print("🔄 Iniciando carregamento de reservas para usuário: \(userId)")
        
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await fetchReservationsUseCase.execute(userId: userId)
            self.reservas = result.reservations
            self.coworkings = result.spaces
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                return
            }
            self.errorMessage = "Erro ao carregar reservas: \(error.localizedDescription)"
        }
    }
}
