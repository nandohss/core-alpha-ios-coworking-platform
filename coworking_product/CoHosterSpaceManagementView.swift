// CoHosterSpaceManagementView.swift
// Created by AI Assistant

import SwiftUI
import PhotosUI

// MARK: - DTOs auxiliares
struct FacilityCategory: Identifiable, Hashable {
    let id: String
    let name: String
    var facilities: [Facility]
}

struct Facility: Identifiable, Hashable {
    let id: String
    let name: String
    let systemImage: String?
}

struct ManagedSpace {
    var title: String
    var capacity: Int
    var pricePerHour: Double
    var description: String
    var isEnabled: Bool
}

// MARK: - Serviço (stubs)
@MainActor
final class SpaceManagementService {
    // Carregar dados do espaço existente
    func fetchSpace(spaceId: String) async throws -> ManagedSpace {
        // TODO: Integrar Amplify/API Gateway/Lambda
        // Stub de retorno
        return ManagedSpace(
            title: "Meu Espaço",
            capacity: 10,
            pricePerHour: 120.0,
            description: "Espaço aconchegante para reuniões.",
            isEnabled: true
        )
    }

    // Salvar campos básicos do espaço
    func saveSpaceBasics(_ space: ManagedSpace) async throws {
        // TODO: Integrar Amplify Mutation / API
        // Stub: apenas simula delay
        try await Task.sleep(nanoseconds: 400_000_000)
    }

    // Atualizar flags: habilitar reservas e aprovação automática
    func updateFlags(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws {
        // TODO: Lambda para atualizar flags
        try await Task.sleep(nanoseconds: 250_000_000)
    }

    // Upload de foto para S3 (retorna URL público/assinatura curta)
    func uploadPhoto(data: Data, filename: String, spaceId: String) async throws -> URL {
        // TODO: Amplify Storage / S3 PutObject
        try await Task.sleep(nanoseconds: 600_000_000)
        return URL(string: "https://example.com/space/\(spaceId)/\(filename)")!
    }

    // Remover foto do S3
    func deletePhoto(url: URL, spaceId: String) async throws {
        // TODO: Amplify Storage deleteObject
        try await Task.sleep(nanoseconds: 250_000_000)
    }

    // Salvar facilidades
    func saveFacilities(spaceId: String, facilityIDs: [String]) async throws {
        // TODO: Persistir relação espaço-facilidades
        try await Task.sleep(nanoseconds: 300_000_000)
    }

    // Salvar disponibilidade
    func saveAvailability(spaceId: String, weekdays: Set<Int>) async throws {
        // TODO: Persistir disponibilidade
        try await Task.sleep(nanoseconds: 350_000_000)
    }

    // Salvar regras de reserva
    func saveRules(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws {
        // TODO: Persistir regras
        try await Task.sleep(nanoseconds: 300_000_000)
    }
}

// MARK: - ViewModel
@MainActor
final class CoHosterSpaceManagementViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    // Identidade
    let spaceId: String
    private let service = SpaceManagementService()

    // Flags
    @Published var isEnabledForBookings: Bool = true
    @Published var autoApproveBookings: Bool = false

    // Dados básicos
    @Published var title: String = ""
    @Published var capacity: Int = 1
    @Published var pricePerHourBRL: String = "" // campo editável formatado
    @Published var pricePerDayBRL: String = "" // campo editável formatado
    @Published var descriptionText: String = ""

    // Fotos
    @Published var pickedItems: [PhotosPickerItem] = []
    @Published var photoURLs: [URL] = []
    @Published var photoToDelete: URL?
    @Published var isUploading = false

    // Facilidades
    @Published var categories: [FacilityCategory] = []
    @Published var selectedFacilities: Set<Facility> = []
    @Published var facilitiesSearch: String = ""
    @Published var showFacilitiesSheet = false

    // Disponibilidade
    // Dias da semana selecionados (1=Domingo ... 7=Sábado conforme Calendar.current)
    @Published var selectedWeekdays: Set<Int> = []

    // Regras
    @Published var minDurationMinutes: Int = 60
    @Published var bufferMinutes: Int = 15

    init(spaceId: String) {
        self.spaceId = spaceId
    }

    // MARK: - Load
    func load() {
        Task { await loadAsync() }
    }

    private func loadAsync() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let data = try await service.fetchSpace(spaceId: spaceId)
            // popular estado a partir do DTO
            self.title = data.title
            self.capacity = data.capacity
            self.pricePerHourBRL = Self.brlString(from: data.pricePerHour)
            self.descriptionText = data.description
            self.isEnabledForBookings = data.isEnabled
            // Dados simulados
            self.categories = Self.sampleCategories()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Actions
    func saveBasics() {
        Task {
            do {
                let space = ManagedSpace(
                    title: title,
                    capacity: capacity,
                    pricePerHour: Self.brlToDouble(pricePerHourBRL),
                    description: descriptionText,
                    isEnabled: isEnabledForBookings
                )
                try await service.saveSpaceBasics(space)
                successMessage = "Dados salvos com sucesso"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveFlags() {
        Task {
            do {
                try await service.updateFlags(spaceId: spaceId, isEnabled: isEnabledForBookings, autoApprove: autoApproveBookings)
                successMessage = "Status atualizado"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func uploadPickedPhotos() {
        guard !pickedItems.isEmpty else { return }
        isUploading = true
        let currentItems = pickedItems
        pickedItems.removeAll()
        Task {
            defer { isUploading = false }
            for item in currentItems {
                do {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let filename = UUID().uuidString + ".jpg"
                        let url = try await service.uploadPhoto(data: data, filename: filename, spaceId: spaceId)
                        withAnimation { photoURLs.append(url) }
                    }
                } catch {
                    errorMessage = "Falha ao enviar foto: \(error.localizedDescription)"
                }
            }
        }
    }

    func confirmDeletePhoto(_ url: URL) { photoToDelete = url }

    func deleteConfirmedPhoto() {
        guard let url = photoToDelete else { return }
        Task {
            do {
                try await service.deletePhoto(url: url, spaceId: spaceId)
                withAnimation { photoURLs.removeAll { $0 == url } }
                photoToDelete = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveFacilitiesSelection() {
        Task {
            do {
                let ids = selectedFacilities.map { $0.id }
                try await service.saveFacilities(spaceId: spaceId, facilityIDs: ids)
                successMessage = "Facilidades salvas"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveAvailability() {
        Task {
            do {
                try await service.saveAvailability(spaceId: spaceId, weekdays: selectedWeekdays)
                successMessage = "Disponibilidade salva"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func saveRules() {
        Task {
            do {
                try await service.saveRules(spaceId: spaceId, minDurationMinutes: minDurationMinutes, bufferMinutes: bufferMinutes)
                successMessage = "Regras salvas"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - New aggregated saving method
    func saveAll() {
        Task {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            defer { isLoading = false }
            do {
                // Save basics
                let space = ManagedSpace(
                    title: title,
                    capacity: capacity,
                    pricePerHour: Self.brlToDouble(pricePerHourBRL),
                    description: descriptionText,
                    isEnabled: isEnabledForBookings
                )
                try await service.saveSpaceBasics(space)

                // Upload photos if any
                if !pickedItems.isEmpty {
                    isUploading = true
                    let currentItems = pickedItems
                    pickedItems.removeAll()
                    for item in currentItems {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            let filename = UUID().uuidString + ".jpg"
                            let url = try await service.uploadPhoto(data: data, filename: filename, spaceId: spaceId)
                            withAnimation { photoURLs.append(url) }
                        }
                    }
                    isUploading = false
                }

                // Save availability
                try await service.saveAvailability(spaceId: spaceId, weekdays: selectedWeekdays)

                // Save rules
                try await service.saveRules(spaceId: spaceId, minDurationMinutes: minDurationMinutes, bufferMinutes: bufferMinutes)

                successMessage = "Alterações salvas"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Helpers BRL
    static func brlString(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    static func brlToDouble(_ text: String) -> Double {
        let digits = text.filter({ "0123456789".contains($0) })
        let cents = Double(digits) ?? 0
        return cents / 100.0
    }

    static func sampleCategories() -> [FacilityCategory] {
        return [
            FacilityCategory(id: "basic", name: "Básico", facilities: [
                Facility(id: "wifi", name: "Wi-Fi", systemImage: "wifi"),
                Facility(id: "ac", name: "Ar-condicionado", systemImage: "wind"),
                Facility(id: "projector", name: "Projetor", systemImage: "videoprojector")
            ]),
            FacilityCategory(id: "comfort", name: "Conforto", facilities: [
                Facility(id: "coffee", name: "Café", systemImage: "cup.and.saucer"),
                Facility(id: "water", name: "Água filtrada", systemImage: "drop"),
                Facility(id: "parking", name: "Estacionamento", systemImage: "car")
            ]),
            FacilityCategory(id: "office", name: "Escritório", facilities: [
                Facility(id: "whiteboard", name: "Lousa", systemImage: "rectangle.and.pencil.and.ellipsis"),
                Facility(id: "meeting", name: "Sala de reunião", systemImage: "person.3")
            ])
        ]
    }
}

// MARK: - View
struct CoHosterSpaceManagementView: View {
    @StateObject private var vm: CoHosterSpaceManagementViewModel

    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case title
        case priceHour
        case priceDay
        case description
    }

    init(spaceId: String) {
        _vm = StateObject(wrappedValue: CoHosterSpaceManagementViewModel(spaceId: spaceId))
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

    private var isDeleteConfirmationPresented: Binding<Bool> {
        Binding(
            get: { vm.photoToDelete != nil },
            set: { if !$0 { vm.photoToDelete = nil } }
        )
    }

    var body: some View {
        content
            .navigationTitle("Gerenciar espaço")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salvar") { vm.saveAll() }
                        .tint(.black)
                }
            }
            .onAppear { vm.load() }
            .modifier(AlertsModifier(
                isSuccess: isSuccessAlertPresented,
                isError: isErrorAlertPresented,
                isDelete: isDeleteConfirmationPresented,
                successMessage: vm.successMessage ?? "",
                errorMessage: vm.errorMessage ?? "",
                onDelete: vm.deleteConfirmedPhoto
            ))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("OK") { focusedField = nil }
                        .tint(.black)
                }
            }
    }

    private var content: some View {
        Form {
            statusSection
            basicsSection
            photosSection
            facilitiesSection
            availabilitySection
            rulesSection
        }
    }
    
    private struct PriceInputField: View {
        let label: String
        @Binding var text: String
        var focus: FocusState<Field?>.Binding? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                HStack {
                    TextField("R$ 0,00", text: $text)
                        .keyboardType(.numberPad)
                        .onChange(of: text) { newValue in
                            let double = CoHosterSpaceManagementViewModel.brlToDouble(newValue)
                            text = CoHosterSpaceManagementViewModel.brlString(from: double)
                        }
                        .modifier(ApplyFocusModifier(focus: focus, for: label))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.vertical, 4)
        }
    }

    private struct ApplyFocusModifier: ViewModifier {
        let focus: FocusState<Field?>.Binding?
        let target: Field

        init(focus: FocusState<Field?>.Binding?, for label: String) {
            self.focus = focus
            // Map label to field
            if label == "Preço por hora" {
                self.target = .priceHour
            } else {
                self.target = .priceDay
            }
        }

        func body(content: Content) -> some View {
            if let focus = focus {
                content.focused(focus, equals: target)
            } else {
                content
            }
        }
    }

    // MARK: - Sections
    private var statusSection: some View {
        Section(header: Text("Status e aprovação"), footer: EmptyView()) {
            Toggle("Habilitar reservas", isOn: $vm.isEnabledForBookings)
                .tint(.black)
                .onChange(of: vm.isEnabledForBookings) { _ in vm.saveFlags() }
            Toggle("Aprovação automática", isOn: $vm.autoApproveBookings)
                .tint(.black)
                .onChange(of: vm.autoApproveBookings) { _ in vm.saveFlags() }
        }
    }

    private var basicsSection: some View {
        Section(header: Text("Dados do espaço"), footer: Text("O preço é formatado em Real (pt-BR). Toque em Salvar para persistir.")) {
            TextField("Título", text: $vm.title).focused($focusedField, equals: .title)
            Stepper(value: $vm.capacity, in: 1...200) { Text("Capacidade: \(vm.capacity)") }

            HStack(alignment: .top, spacing: 12) {
                PriceInputField(label: "Preço por hora", text: $vm.pricePerHourBRL, focus: $focusedField)
                PriceInputField(label: "Preço por dia", text: $vm.pricePerDayBRL, focus: $focusedField)
            }

            ZStack(alignment: .topLeading) {
                if vm.descriptionText.isEmpty {
                    Text("Escreva a descrição do espaço aqui...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 5)
                }
                TextEditor(text: $vm.descriptionText).focused($focusedField, equals: .description)
                    .frame(minHeight: 80)
            }
        }
    }


    private var photosSection: some View {
        PhotosSectionView(vm: vm)
    }

    private var facilitiesSection: some View {
        FacilitiesSectionView(vm: vm)
    }

    private var availabilitySection: some View {
        Section(header: Text("Disponibilidade"), footer: EmptyView()) {
            WeekdaySelector(selected: $vm.selectedWeekdays)
        }
    }

    private var rulesSection: some View {
        Section(header: Text("Regras de reserva"), footer: EmptyView()) {
            HStack {
                Stepper(value: $vm.minDurationMinutes, in: 30...480, step: 15) {
                    Text("Duração mínima: \(vm.minDurationMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.minDurationMinutes)
            HStack {
                Stepper(value: $vm.bufferMinutes, in: 0...240, step: 5) {
                    Text("Intervalo entre reservas: \(vm.bufferMinutes) min").font(.subheadline)
                }
            }
            .scaleEffect(1.06)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: vm.bufferMinutes)
        }
    }
}

private struct AlertsModifier: ViewModifier {
    let isSuccess: Binding<Bool>
    let isError: Binding<Bool>
    let isDelete: Binding<Bool>
    let successMessage: String
    let errorMessage: String
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("Sucesso", isPresented: isSuccess) {
                Button("OK", role: .cancel) {}
            } message: { Text(successMessage) }
            .alert("Atenção", isPresented: isError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
            .confirmationDialog("Remover foto?", isPresented: isDelete) {
                Button("Remover", role: .destructive) { onDelete() }
                Button("Cancelar", role: .cancel) {}
            }
    }
}

// MARK: - Subviews auxiliares

// Tag reutilizável no estilo das telas de cadastro
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

// Dias da semana dentro de uma "box" com tags pretas/cinzas
private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>

    // 1 = Domingo, 2 = Segunda, ..., 7 = Sábado
    private let weekdays: [(label: String, index: Int)] = [
        ("Seg", 2),
        ("Ter", 3),
        ("Qua", 4),
        ("Qui", 5),
        ("Sex", 6),
        ("Sáb", 7),
        ("Dom", 1)
    ]

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
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

private struct PhotosSectionView: View {
    @ObservedObject var vm: CoHosterSpaceManagementViewModel

    var body: some View {
        Section(header: Text("Fotos"), footer: Text("As fotos serão enviadas ao salvar.")) {
            if vm.isUploading { ProgressView("Enviando fotos...") }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.photoURLs, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            ThumbnailView(url: url)
                                .frame(width: 120, height: 90)
                                .clipped()
                                .cornerRadius(8)

                            Button(role: .destructive) { vm.confirmDeletePhoto(url) } label: {
                                Image(systemName: "xmark.circle.fill").symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                            .tint(.red)
                        }
                    }
                    ForEach(Array(vm.pickedItems.enumerated()), id: \.offset) { _, item in
                        PickedItemThumbnail(item: item)
                            .frame(width: 120, height: 90)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.vertical, 4)
            }
            PhotosPicker(selection: $vm.pickedItems, maxSelectionCount: 6, matching: .images) {
                Label("Adicionar fotos", systemImage: "plus")
            }
            .tint(.black)
        }
    }
}

private struct ThumbnailView: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Image(systemName: "photo").font(.title)
            @unknown default:
                EmptyView()
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

// Facilidades no mesmo estilo de tags da tela de cadastro
private struct FacilitiesSectionView: View {
    @ObservedObject var vm: CoHosterSpaceManagementViewModel

    private var allFacilities: [Facility] {
        vm.categories.flatMap { $0.facilities }
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
                            let isSelected = vm.selectedFacilities.contains(facility)
                            SelectableTag(title: facility.name, isSelected: isSelected) {
                                if isSelected {
                                    vm.selectedFacilities.remove(facility)
                                } else {
                                    vm.selectedFacilities.insert(facility)
                                }
                                // opcional: salvar a cada toque
                                // vm.saveFacilitiesSelection()
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Preview
// #Preview {
//     NavigationStack { CoHosterSpaceManagementView(spaceId: "space-123") }
// }

