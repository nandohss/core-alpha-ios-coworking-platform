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
    func saveAvailability(spaceId: String, weekdays: Set<Int>, availableDates: Set<DateComponents>, blockedDates: Set<DateComponents>) async throws {
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
    @Published var availableDates: Set<DateComponents> = []
    @Published var blockedDates: Set<DateComponents> = []

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
                try await service.saveAvailability(spaceId: spaceId, weekdays: selectedWeekdays, availableDates: availableDates, blockedDates: blockedDates)
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

    // MARK: - Helpers BRL
    static func brlString(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    static func brlToDouble(_ text: String) -> Double {
        let digits = text.filter({ "0123456789".contains($0) })
        let cents = Double(digits) ?? 0
        return cents / 100.0
    }

    static func sampleCategories() -> [FacilityCategory] {
        return [
            FacilityCategory(id: "basic", name: "Básico", facilities: [
                Facility(id: "wifi", name: "Wi‑Fi", systemImage: "wifi"),
                Facility(id: "ac", name: "Ar Cond.", systemImage: "wind"),
                Facility(id: "projector", name: "Projetor", systemImage: "videoprojector"),
            ]),
            FacilityCategory(id: "comfort", name: "Conforto", facilities: [
                Facility(id: "coffee", name: "Café", systemImage: "cup.and.saucer"),
                Facility(id: "water", name: "Água", systemImage: "drop"),
                Facility(id: "parking", name: "Estacionamento", systemImage: "car"),
            ]),
            FacilityCategory(id: "office", name: "Escritório", facilities: [
                Facility(id: "whiteboard", name: "Quadro", systemImage: "rectangle.and.pencil.and.ellipsis"),
                Facility(id: "meeting", name: "Sala Reunião", systemImage: "person.3"),
            ]),
        ]
    }
}

// MARK: - View
struct CoHosterSpaceManagementView: View {
    @StateObject private var vm: CoHosterSpaceManagementViewModel

    init(spaceId: String) {
        _vm = StateObject(wrappedValue: CoHosterSpaceManagementViewModel(spaceId: spaceId))
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
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Salvar") { vm.saveBasics() } } }
        .onAppear { vm.load() }
        .alert("Sucesso", isPresented: Binding(get: { vm.successMessage != nil }, set: { if !$0 { vm.successMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.successMessage ?? "") }
        .alert("Atenção", isPresented: Binding(get: { vm.errorMessage != nil }, set: { if !$0 { vm.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(vm.errorMessage ?? "") }
        .confirmationDialog("Remover foto?", isPresented: Binding(get: { vm.photoToDelete != nil }, set: { if !$0 { vm.photoToDelete = nil } })) {
            Button("Remover", role: .destructive) { vm.deleteConfirmedPhoto() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Sections
    private var statusSection: some View {
        Section(header: Text("Status e aprovação"), footer: EmptyView()) {
            Toggle("Habilitar reservas", isOn: $vm.isEnabledForBookings)
                .onChange(of: vm.isEnabledForBookings) { _ in vm.saveFlags() }
            Toggle("Aprovação automática", isOn: $vm.autoApproveBookings)
                .onChange(of: vm.autoApproveBookings) { _ in vm.saveFlags() }
        }
    }

    private var basicsSection: some View {
        Section(header: Text("Dados do espaço"), footer: Text("O preço é formatado em Real (pt-BR). Toque em Salvar para persistir.")) {
            TextField("Título", text: $vm.title)
            Stepper(value: $vm.capacity, in: 1...200) { Text("Capacidade: \(vm.capacity)") }
            TextField("Preço/hora (BRL)", text: $vm.pricePerHourBRL)
                .keyboardType(.numberPad)
                .onChange(of: vm.pricePerHourBRL) { new in
                    let double = CoHosterSpaceManagementViewModel.brlToDouble(new)
                    vm.pricePerHourBRL = CoHosterSpaceManagementViewModel.brlString(from: double)
                }
            TextEditor(text: $vm.descriptionText)
                .frame(minHeight: 80)
        }
    }

    private var photosSection: some View {
        Section(header: Text("Fotos"), footer: Text("As fotos são enviadas automaticamente ao selecionar.")) {
            if vm.isUploading { ProgressView("Enviando fotos...") }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.photoURLs, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty: ProgressView()
                                case .success(let image): image.resizable().scaledToFill()
                                case .failure: Image(systemName: "photo").font(.title)
                                @unknown default: EmptyView()
                                }
                            }
                            .frame(width: 120, height: 90)
                            .clipped()
                            .cornerRadius(8)

                            Button(role: .destructive) { vm.confirmDeletePhoto(url) } label: {
                                Image(systemName: "xmark.circle.fill").symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            PhotosPicker(selection: $vm.pickedItems, maxSelectionCount: 6, matching: .images) {
                Label("Adicionar fotos", systemImage: "plus")
            }
            .onChange(of: vm.pickedItems) { _ in vm.uploadPickedPhotos() }
        }
    }

    private var facilitiesSection: some View {
        Section(header: Text("Facilidades"), footer: EmptyView()) {
            if vm.selectedFacilities.isEmpty {
                Text("Nenhuma facilidade selecionada").foregroundStyle(.secondary)
            } else {
                let columns = [GridItem(.adaptive(minimum: 120), spacing: 8)]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                    ForEach(Array(vm.selectedFacilities), id: \.self) { facility in
                        HStack(spacing: 6) {
                            if let s = facility.systemImage { Image(systemName: s) }
                            Text(facility.name)
                            Button(role: .destructive) { vm.selectedFacilities.remove(facility) } label: {
                                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Capsule().fill(Color(.secondarySystemBackground)))
                    }
                }
            }
            Button { vm.showFacilitiesSheet = true } label: { Label("Selecionar facilidades", systemImage: "slider.horizontal.3") }
        }
        .sheet(isPresented: $vm.showFacilitiesSheet) {
            FacilitiesPickerView(categories: vm.categories, preselected: vm.selectedFacilities) { selection in
                vm.selectedFacilities = selection
                vm.saveFacilitiesSelection()
            }
        }
    }

    private var availabilitySection: some View {
        Section(header: Text("Disponibilidade"), footer: EmptyView()) {
            WeekdaySelector(selected: $vm.selectedWeekdays)
            VStack(alignment: .leading) {
                Text("Datas disponíveis")
                MultiDatePicker(selection: $vm.availableDates) { EmptyView() }
            }
            VStack(alignment: .leading) {
                Text("Datas bloqueadas")
                MultiDatePicker(selection: $vm.blockedDates) { EmptyView() }
            }
            Button("Salvar disponibilidade") { vm.saveAvailability() }
        }
    }

    private var rulesSection: some View {
        Section(header: Text("Regras de reserva"), footer: EmptyView()) {
            Stepper(value: $vm.minDurationMinutes, in: 30...480, step: 15) {
                Text("Duração mínima: \(vm.minDurationMinutes) min")
            }
            Stepper(value: $vm.bufferMinutes, in: 0...240, step: 5) {
                Text("Intervalo entre reservas: \(vm.bufferMinutes) min")
            }
            Button("Salvar regras") { vm.saveRules() }
        }
    }
}

// MARK: - Subviews auxiliares
private struct WeekdaySelector: View {
    @Binding var selected: Set<Int>
    private let symbols = Calendar.current.shortWeekdaySymbols // Depende da locale

    var body: some View {
        HStack {
            ForEach(1...7, id: \.self) { index in
                let isOn = selected.contains(index)
                Button {
                    if isOn { selected.remove(index) } else { selected.insert(index) }
                } label: {
                    Text(symbols[index - 1])
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(isOn ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isOn ? Color.accentColor : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct FacilitiesPickerView: View {
    let categories: [FacilityCategory]
    let preselected: Set<Facility>
    var onDone: (Set<Facility>) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var facilityLookup: [String: Facility] {
        Dictionary(uniqueKeysWithValues: categories.flatMap { $0.facilities }.map { ($0.id, $0) })
    }

    @State private var selectedIDs: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                if !search.isEmpty {
                    let all = categories.flatMap { $0.facilities }
                    let filtered = all.filter { $0.name.localizedCaseInsensitiveContains(search) }
                    Section {
                        ForEach(filtered) { item in
                            HStack {
                                if let s = item.systemImage { Image(systemName: s) }
                                Text(item.name)
                                Spacer()
                                if selectedIDs.contains(item.id) { Image(systemName: "checkmark").foregroundStyle(.accent) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) } else { selectedIDs.insert(item.id) }
                            }
                        }
                    } header: {
                        Text("Resultados")
                    }
                } else {
                    ForEach(categories) { cat in
                        Section {
                            ForEach(cat.facilities) { item in
                                HStack {
                                    if let s = item.systemImage { Image(systemName: s) }
                                    Text(item.name)
                                    Spacer()
                                    if selectedIDs.contains(item.id) { Image(systemName: "checkmark").foregroundStyle(.accent) }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedIDs.contains(item.id) { selectedIDs.remove(item.id) } else { selectedIDs.insert(item.id) }
                                }
                            }
                        } header: {
                            Text(cat.name)
                        }
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar facilidades")
            .navigationTitle("Facilidades")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") {
                        let result = Set(selectedIDs.compactMap { facilityLookup[$0] })
                        onDone(result)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedIDs = Set(preselected.map { $0.id })
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack { CoHosterSpaceManagementView(spaceId: "space-123") }
}

