import Foundation
import Combine

@MainActor
class DateSelectionViewModel: ObservableObject {
    // MARK: - Dependencies
    private let checkAvailabilityUseCase: CheckReservationAvailabilityUseCase

    // MARK: - Published State
    @Published var space: CoworkingSpace
    @Published var selectedDate: Date = Date()
    @Published var selectedHours: Set<Int> = []
    @Published var reservedHours: [Int] = []
    @Published var blockedDates: Set<Date> = []
    @Published var isLoading: Bool = false
    
    // MARK: - Initialization
    init(
        space: CoworkingSpace,
        checkAvailabilityUseCase: CheckReservationAvailabilityUseCase
    ) {
        self.space = space
        self.checkAvailabilityUseCase = checkAvailabilityUseCase
        
        // Initial validation
        self.validateAndAdjustDate()
        
        Task { await fetchBlockedDates() }
    }
    
    // ...
    
    func update(space: CoworkingSpace) {
        if self.space != space {
            self.space = space
            Task { await fetchBlockedDates() }
        }
    }
    
    // MARK: - Computed Properties
    
    var isFullDay: Bool {
        space.pricing.isFullDay
    }
    
    var availableHours: [Int] {
        if isFullDay { return Array(0...23) }
        
        let start = Int(space.availability.startHour?.prefix(2) ?? "") ?? 8
        var end = Int(space.availability.endHour?.prefix(2) ?? "") ?? 20
        
        // Treat 00:00 as 24:00 (Midnight closing)
        if end == 0 { end = 24 }
        
        if start >= end { return Array(8...20) }
        return Array(start..<end)
    }
    
    var totalHours: Int { selectedHours.count }
    var pricePerHour: Double { space.pricing.hourlyRate }
    
    var totalPrice: Double {
        if isFullDay, let dayPrice = space.pricing.dailyRate {
            return dayPrice
        }
        return Double(totalHours) * pricePerHour
    }
    
    var isSelectionValid: Bool {
        totalHours > 0
    }

    func fetchBlockedDates() async {
        // Only relevant for Full Day spaces per requirement "quando a reserva de dia inteiro está habilitada"
        guard isFullDay, let hosterId = space.hosterId else { return }
        
        do {
            let reservations = try await checkAvailabilityUseCase.fetchReservations(
                hosterId: hosterId,
                spaceId: space.id
            )
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            var blocked: Set<Date> = []
            
            for res in reservations {
                let status = res.status.uppercased()
                if (status == "CONFIRMED" || status == "PENDING"),
                   let date = formatter.date(from: res.dateReservation) {
                    blocked.insert(date)
                }
            }
            
            await MainActor.run {
                self.blockedDates = blocked
                print("DEBUG: Blocked Dates for Calendar: \(blocked.count)")
            }
        } catch {
            print("❌ Error fetching blocked dates: \(error.localizedDescription)")
        }
    }
    
    func onDateChanged() {
        Task {
            await fetchReservedHours()
        }
    }
    
    func toggleHour(_ hour: Int) {
        if selectedHours.contains(hour) {
            selectedHours.remove(hour)
        } else {
            selectedHours.insert(hour)
        }
    }
    
    func fetchReservedHours() async {
        isLoading = true
        let allHours = availableHours.map { String($0) }
        print("DEBUG: Checking availability for isFullDay=\(isFullDay) Date=\(selectedDate) Hours=\(allHours)")
        
        do {
            let reserved = try await checkAvailabilityUseCase.execute(
                spaceId: space.id,
                date: formatDateOnly(selectedDate),
                hours: allHours,
                hosterId: space.hosterId ?? ""
            )
            
            reservedHours = reserved.compactMap { Int($0) }
            print("DEBUG: Reserved Hours: \(reservedHours)")
            
            // Auto-selection for Full Day
            if isFullDay {
                handleFullDayAutoSelection()
            } else {
                selectedHours = selectedHours.filter { !reservedHours.contains($0) }
            }
            
        } catch {
            print("❌ Error fetching availability: \(error.localizedDescription)")
            reservedHours = []
            // Retry auto-selection even on error (assume available?)
             if isFullDay {
                handleFullDayAutoSelection()
            }
        }
        
        isLoading = false
    }
    
    private func handleFullDayAutoSelection() {
        print("DEBUG: Running Auto Selection. Available: \(availableHours.count)")
        let valid = availableHours.filter {
            !reservedHours.contains($0) && !isHourPast($0)
        }
        print("DEBUG: Valid Hours found: \(valid.count)")
        selectedHours = Set(valid)
        print("DEBUG: Selected Hours Set: \(selectedHours.count)")
    }

    // MARK: - Helpers
    
    func isHourPast(_ hour: Int) -> Bool {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
             let currentHour = calendar.component(.hour, from: Date())
             return hour <= currentHour
        }
        return false
    }
    
    private func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
    
    // MARK: - Date Validation Logic
    
    func validateAndAdjustDate() {
        var date = selectedDate
        // Prevent infinite loop
        for _ in 0..<365 {
            if isDayAvailable(date) {
                if date != selectedDate {
                    selectedDate = date
                }
                return
            }
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
    }
    
    func isDayAvailable(_ date: Date) -> Bool {
        guard let dias = space.availability.weekdays, !dias.isEmpty else { return true }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        // Mapping: Dom=1, Seg=2, ...
        let map: [String: Int] = [
            "Dom": 1, "Seg": 2, "Ter": 3, "Qua": 4, "Qui": 5, "Sex": 6, "Sáb": 7
        ]
        
        return dias.contains { dayStr in
             let norm = String(dayStr.prefix(3)).capitalized
             return map[norm] == weekday
        }
    }
}
