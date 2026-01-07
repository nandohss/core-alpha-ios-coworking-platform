import SwiftUI

struct FacilitiesSectionView: View {
    let categories: [FacilityCategory]
    @Binding var selectedFacilities: Set<Facility>

    private var allFacilities: [Facility] {
        let catalog = categories.flatMap { $0.facilities }
        if catalog.isEmpty {
            // Fallback: se não há catálogo carregado, use as selecionadas como universo
            return Array(selectedFacilities).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        return catalog.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Section(header: Text("Facilidades"), footer: EmptyView()) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Selecione as facilidades disponíveis no espaço")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if allFacilities.isEmpty {
                    Text("Nenhuma facilidade configurada.")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                } else {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 12) {
                        ForEach(allFacilities, id: \.self) { facility in
                            let isSelected = selectedFacilities.contains(facility)
                            SelectableTag(title: facility.name, isSelected: isSelected) {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                if isSelected {
                                    selectedFacilities.remove(facility)
                                } else {
                                    selectedFacilities.insert(facility)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}
