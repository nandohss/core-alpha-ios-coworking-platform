// Presentation/CoHosterSpaceManagement/Views/CoHosterSpaceManagementView.swift
import SwiftUI
import PhotosUI

struct CoHosterSpaceManagementView: View {
    @StateObject private var vm: CoHosterSpaceManagementViewModel
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title, priceHour, priceDay, description
    }

    // Injete o ViewModel já pronto (com os casos de uso) na inicialização
    init(viewModel: CoHosterSpaceManagementViewModel) {
        _vm = StateObject(wrappedValue: viewModel)
    }

    private var isSuccessAlertPresented: Binding<Bool> {
        Binding(
            get: { vm.successMessage != nil },
            set: { if !$0 { vm.successMessage = nil } }
        )
    }
    private var isErrorAlertPresented: Binding<Bool> {
        Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )
    }

    var body: some View {
        Form {
            statusSection
            basicsSection
            photosSection
            facilitiesSection
            availabilitySection
            rulesSection
        }
        .navigationTitle("Gerenciar espaço")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Salvar") { Task { await vm.saveAll() } }
                    .tint(.black)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") { focusedField = nil }
                    .tint(.black)
            }
        }
        .onAppear { Task { await vm.load() } }
        .alert("Sucesso", isPresented: isSuccessAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.successMessage ?? "") }
        .alert("Atenção", isPresented: isErrorAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.errorMessage ?? "") }
    }

    // MARK: - Seções de UI

    private var statusSection: some View {
        Section(header: Text("Status e aprovação")) {
            Toggle("Habilitar reservas", isOn: $vm.isEnabledForBookings)
                .tint(.black)
                .onChange(of: vm.isEnabledForBookings) { _ in /* vm.saveFlags() */ }
            Toggle("Aprovação automática", isOn: $vm.autoApproveBookings)
                .tint(.black)
                .onChange(of: vm.autoApproveBookings) { _ in /* vm.saveFlags() */ }
        }
    }

    private var basicsSection: some View {
        Section(header: Text("Dados do espaço")) {
            TextField("Título", text: $vm.title)
                .focused($focusedField, equals: CoHosterSpaceManagementView.Field.title)
            Stepper(value: $vm.capacity, in: 1...200) {
                Text("Capacidade: \(vm.capacity)")
            }
            .onChange(of: vm.capacity) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            HStack(alignment: .top, spacing: 12) {
                PriceInputField(label: "Preço por hora", text: $vm.pricePerHourBRL, target: .priceHour, focus: $focusedField)
                // Se quiser, inclua também preço por dia, se o ViewModel trouxer esse campo
            }
            ZStack(alignment: .topLeading) {
                if vm.descriptionText.isEmpty {
                    Text("Escreva a descrição do espaço aqui...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $vm.descriptionText)
                    .focused($focusedField, equals: CoHosterSpaceManagementView.Field.description)
                    .frame(minHeight: 80)
            }
        }
    }

    private var photosSection: some View {
        PhotosSectionView(
            pickedItems: $vm.pickedItems,
            photoURLs: $vm.photoURLs,
            isUploading: vm.isUploading,
            onDelete: vm.confirmDeletePhoto
        )
    }

    private var facilitiesSection: some View {
        FacilitiesSectionView(categories: vm.categories, selectedFacilities: $vm.selectedFacilities)
    }

    private var availabilitySection: some View {
        Section(header: Text("Disponibilidade")) {
            WeekdaySelector(selected: $vm.selectedWeekdays)
        }
    }

    private var rulesSection: some View {
        Section(header: Text("Regras de reserva")) {
            HStack {
                Stepper(value: $vm.minDurationMinutes, in: 30...480, step: 15) {
                    Text("Duração mínima: \(vm.minDurationMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.minDurationMinutes)
            .onChange(of: vm.minDurationMinutes) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
            HStack {
                Stepper(value: $vm.bufferMinutes, in: 0...240, step: 5) {
                    Text("Intervalo entre reservas: \(vm.bufferMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.bufferMinutes)
            .onChange(of: vm.bufferMinutes) { _ in
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Subviews utilitárias

// MARK: - Subviews utilitárias

// MARK: - Subviews utilitárias

private struct PriceInputField: View {
    let label: String
    @Binding var text: String
    let target: CoHosterSpaceManagementView.Field
    var focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding? = nil
    
    @State private var shouldOverwrite = false

    private var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
            HStack(spacing: 4) {
                Text("R$")
                    .foregroundStyle(.primary)
                    .font(.body)
                
                TextField("0,00", text: Binding(
                    get: {
                        let cleaned = text
                            .replacingOccurrences(of: "R$", with: "")
                            .replacingOccurrences(of: " ", with: "")
                            .trimmingCharacters(in: .whitespaces)
                        return cleaned.isEmpty ? "0,00" : cleaned
                    },
                    set: { newValue in
                        let oldDigits = text.filter { "0123456789".contains($0) }
                        let newDigits = newValue.filter { "0123456789".contains($0) }
                        
                        var finalDigits = newDigits
                        
                        if shouldOverwrite {
                            // Find the new characters added
                            if newDigits.count > oldDigits.count {
                                // Simple heuristic: user typed a number, discard old state
                                // We take the difference (new chars)
                                var temp = newDigits
                                for char in oldDigits {
                                    if let index = temp.firstIndex(of: char) {
                                        temp.remove(at: index)
                                    }
                                }
                                if !temp.isEmpty {
                                    finalDigits = temp
                                }
                            }
                            shouldOverwrite = false
                        }
                        
                        if let number = Double(finalDigits) {
                            let value = number / 100.0
                            let formatted = decimalFormatter.string(from: NSNumber(value: value)) ?? "0,00"
                            text = "R$ \(formatted)"
                        } else {
                            text = ""
                        }
                    }
                ))
                .keyboardType(.numberPad)
                .bindFocus(focus, target: target)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
            )
            // Properly bind focus
            .onAppear {
                // Ensure initialization
            }
        }
        .padding(.vertical, 4)
        // Handle focus changes manually since valid .focused() syntax for optional binding is tricky here
        // Actually, we can just use the .focused(binding, equals: value) modifier if we forward it properly.
        .onChange(of: focus?.wrappedValue) { newFocus in
            if newFocus == target {
                shouldOverwrite = true
            }
        }
    }
}

// Extension to apply focus easily
extension View {
    func bindFocus(_ focus: FocusState<CoHosterSpaceManagementView.Field?>.Binding?, target: CoHosterSpaceManagementView.Field) -> some View {
        if let focus = focus {
            return AnyView(self.focused(focus, equals: target))
        } else {
            return AnyView(self)
        }
    }
}


private struct SelectableTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isSelected ? Color.black : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .black)
        }
        .buttonStyle(.plain)
    }
}

private struct WeekdaySelector: View {
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

private struct ThumbnailView: View {
    let url: URL
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty: ProgressView()
            case .success(let image): image.resizable().scaledToFill()
            case .failure: Image(systemName: "photo").font(.title)
            @unknown default: EmptyView()
            }
        }
    }
}

private struct PickedItemThumbnail: View {
    let item: PhotosPickerItem
    @State private var image: Image? = nil

    var body: some View {
        ZStack {
            if let image = image {
                image.resizable().scaledToFill()
            } else {
                ProgressView()
            }
        }
        .task(id: item) {
            if let data = try? await item.loadTransferable(type: Data.self),
               let ui = UIImage(data: data) {
                image = Image(uiImage: ui)
            }
        }
    }
}

// MARK: - Extracted Photos Section
private struct PhotosSectionView: View {
    @Binding var pickedItems: [PhotosPickerItem]
    @Binding var photoURLs: [URL]
    let isUploading: Bool
    let onDelete: (URL) -> Void

    var body: some View {
        Section(header: Text("Fotos"), footer: Text("As fotos serão enviadas ao salvar.")) {
            if isUploading {
                ProgressView("Enviando fotos...")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Fotos já enviadas
                    ForEach(photoURLs, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            ThumbnailView(url: url)
                                .frame(width: 120, height: 90)
                                .clipped()
                                .cornerRadius(8)

                            Button(role: .destructive) {
                                onDelete(url)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                            .tint(.red)
                        }
                    }

                    // Fotos recém-selecionadas
                    ForEach(Array(pickedItems.enumerated()), id: \.offset) { _, item in
                        PickedItemThumbnail(item: item)
                            .frame(width: 120, height: 90)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }

            PhotosPicker(selection: $pickedItems, maxSelectionCount: 6, matching: .images) {
                Label("Adicionar fotos", systemImage: "plus")
            }
            .tint(.black)
        }
    }
}

private struct FacilitiesSectionView: View {
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

