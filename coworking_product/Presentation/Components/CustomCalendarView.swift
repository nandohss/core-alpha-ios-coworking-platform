import SwiftUI

struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let allowedWeekdays: [String]? // Ex: ["Seg", "Ter", ...]
    
    @State private var currentMonth: Date = Date()
    private let calendar = Calendar.current
    private let daysOfWeek = ["D", "S", "T", "Q", "Q", "S", "S"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header: Mês/Ano e Navegação
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(isPastMonth(currentMonth))
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Grid de Dias da Semana
            HStack(spacing: 0) {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid de Datas
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                ForEach(days, id: \.id) { day in
                    if let date = day.date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isSelectable: isDateSelectable(date)
                        ) {
                            withAnimation {
                                selectedDate = date
                            }
                        }
                    } else {
                        Text("")
                            .frame(width: 44, height: 44)
                    }
                }
            }
        }
        .onAppear {
            currentMonth = selectedDate
        }
    }
    
    // MARK: - Logic
    
    struct CalendarDay: Identifiable {
        let id = UUID()
        let date: Date?
    }
    
    private var days: [CalendarDay] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Offset for Sunday=1.
        let offset = firstWeekday - 1
        
        var result: [CalendarDay] = []
        
        // Empty slots
        for _ in 0..<offset {
            result.append(CalendarDay(date: nil))
        }
        
        // Real days
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                result.append(CalendarDay(date: date))
            }
        }
        
        return result
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func isPastMonth(_ date: Date) -> Bool {
        let now = Date()
        return calendar.compare(date, to: now, toGranularity: .month) == .orderedAscending
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).capitalized
    }
    
    private func isDateSelectable(_ date: Date) -> Bool {
        if calendar.compare(date, to: Date(), toGranularity: .day) == .orderedAscending {
            return false
        }
        
        guard let allowed = allowedWeekdays, !allowed.isEmpty else { return true }
        
        let weekday = calendar.component(.weekday, from: date)
        let map: [String: Int] = [
            "Dom": 1, "Seg": 2, "Ter": 3, "Qua": 4, "Qui": 5, "Sex": 6, "Sáb": 7
        ]
        
        return allowed.contains { dayStr in
            let norm = String(dayStr.prefix(3)).capitalized
            return map[norm] == weekday
        }
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isSelectable: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                .foregroundColor(foregroundColor)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .disabled(!isSelectable)
    }
    
    private var foregroundColor: Color {
        if isSelected { return .white }
        if !isSelectable { return .gray.opacity(0.4) } // Visualmente desabilitado
        return .black
    }
    
    private var backgroundColor: Color {
        if isSelected { return .black }
        return .clear
    }
}
