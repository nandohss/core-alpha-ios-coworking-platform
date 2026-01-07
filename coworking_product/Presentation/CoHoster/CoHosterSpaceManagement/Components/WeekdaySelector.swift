import SwiftUI

struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let weekdays: [(label: String, index: Int)] = [
        ("Seg", 2), ("Ter", 3), ("Qua", 4), ("Qui", 5),
        ("Sex", 6), ("Sáb", 7), ("Dom", 1)
    ]
    private let columns: [GridItem] = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dias da semana")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                ForEach(weekdays, id: \.index) { day in
                    let isOn = selected.contains(day.index)
                    SelectableTag(title: day.label, isSelected: isOn) {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        if isOn {
                            selected.remove(day.index)
                        } else {
                            selected.insert(day.index)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
