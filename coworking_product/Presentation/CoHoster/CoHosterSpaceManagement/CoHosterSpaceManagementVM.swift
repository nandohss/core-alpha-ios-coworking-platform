// Presentation/CoHosterSpaceManagement/ViewModels/CoHosterSpaceManagementViewModel.swift
import SwiftUI
import Foundation
import PhotosUI

@MainActor
final class CoHosterSpaceManagementViewModel: ObservableObject {
    // MARK: - Publicados para a View
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var title: String = ""
    @Published var capacity: Int = 1
    @Published var pricePerHourBRL: String = ""
    @Published var pricePerDayBRL: String = ""
    @Published var descriptionText: String = ""
    @Published var isEnabledForBookings: Bool = true
    @Published var autoApproveBookings: Bool = false
    @Published var rules: String = ""
    @Published var startTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @Published var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!

    @Published var isFullDay: Bool = false
    
    // Contact Section
    @Published var email: String = ""
    @Published var ddd: String = ""
    @Published var phoneNumber: String = ""
    @Published var companyName: String = ""

    @Published var photoURLs: [URL] = []
    @Published var categories: [FacilityCategory] = []
    @Published var selectedFacilities: Set<Facility> = []
    @Published var selectedWeekdays: Set<Int> = []
    @Published var minDurationMinutes: Int = 60
    @Published var bufferMinutes: Int = 15
    @Published var facilityItems: [FacilityItem] = []

    @Published var pickedItems: [PhotosPickerItem] = []
    @Published var isUploading: Bool = false
    @Published var photoToDelete: URL?

    // MARK: - Dependências (casos de uso do domínio)
    private let fetchSpaceUseCase: any FetchSpaceUseCase
    private let fetchFacilitiesUseCase: any FetchFacilitiesUseCase
    private let saveSpaceUseCase: any SaveSpaceUseCase
    private let uploadPhotoUseCase: any UploadPhotoUseCase
    private let saveFacilitiesUseCase: any SaveFacilitiesUseCase
    private let saveAvailabilityUseCase: any SaveAvailabilityUseCase
    private let saveRulesUseCase: any SaveRulesUseCase
    private let updateSpaceFlagsUseCase: any UpdateSpaceFlagsUseCase
    private let saveSpaceAllUseCase: any SaveSpaceAllUseCase

    private let spaceId: String

    init(
        spaceId: String,
        fetchSpaceUseCase: any FetchSpaceUseCase,
        fetchFacilitiesUseCase: any FetchFacilitiesUseCase,
        saveSpaceUseCase: any SaveSpaceUseCase,
        uploadPhotoUseCase: any UploadPhotoUseCase,
        saveFacilitiesUseCase: any SaveFacilitiesUseCase,
        saveAvailabilityUseCase: any SaveAvailabilityUseCase,
        saveRulesUseCase: any SaveRulesUseCase,
        updateSpaceFlagsUseCase: any UpdateSpaceFlagsUseCase,
        saveSpaceAllUseCase: any SaveSpaceAllUseCase
    ) {
        self.spaceId = spaceId
        self.fetchSpaceUseCase = fetchSpaceUseCase
        self.fetchFacilitiesUseCase = fetchFacilitiesUseCase
        self.saveSpaceUseCase = saveSpaceUseCase
        self.uploadPhotoUseCase = uploadPhotoUseCase
        self.saveFacilitiesUseCase = saveFacilitiesUseCase
        self.saveAvailabilityUseCase = saveAvailabilityUseCase
        self.saveRulesUseCase = saveRulesUseCase
        self.updateSpaceFlagsUseCase = updateSpaceFlagsUseCase
        self.saveSpaceAllUseCase = saveSpaceAllUseCase
    }

    // Carregar dados do espaço
    func load() async {
        print("🔸 CoHosterSpaceManagementViewModel.load() for spaceId:", spaceId)
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let space = try await fetchSpaceUseCase.execute(spaceId: spaceId)
            self.title = space.title
            self.capacity = space.capacity
            self.pricePerHourBRL = Self.brlString(from: space.pricePerHour)
            if let dayPrice = space.pricePerDay {
                self.pricePerDayBRL = Self.brlString(from: dayPrice)
            } else {
                self.pricePerDayBRL = "" 
            }
            self.descriptionText = space.description
            self.isEnabledForBookings = space.isEnabled
            self.rules = space.rules
            
            // Format time strings (HH:mm) to Date
            if let start = space.startTime, !start.isEmpty {
                self.startTime = Self.date(from: start) ?? self.startTime
            }
            if let end = space.endTime, !end.isEmpty {
                self.endTime = Self.date(from: end) ?? self.endTime
            }
            
            // Direct assignment from domain
            self.isFullDay = space.isFullDay
            
            // Populating Contact Fields
            self.email = space.email ?? ""
            self.ddd = space.ddd ?? ""
            self.phoneNumber = space.phoneNumber ?? ""
            self.companyName = space.companyName ?? ""
            
            self.selectedWeekdays = Set(space.weekdays)
            self.minDurationMinutes = space.minDurationMinutes
            self.bufferMinutes = space.bufferMinutes
            // Carregar facilities
            let facilities = try await fetchFacilitiesUseCase.execute()
            // Preencher categorias com uma categoria padrão usando as facilities retornadas
            let defaultCategory = FacilityCategory(id: "general", name: "Geral", facilities: facilities)
            self.categories = [defaultCategory]
            
            // Restore pre-selection of facilities
            let facilitiesMap = Dictionary(uniqueKeysWithValues: facilities.map { ($0.name, $0) })
            let matched = space.amenities.compactMap { facilitiesMap[$0] }
            self.selectedFacilities = Set(matched)
            
            // Map facilities to presentation items for FacilityView
            self.facilityItems = facilities.map { FacilityItem(from: $0.name) }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Marcar foto para exclusão (confirmação via alerta)
    func confirmDeletePhoto(_ url: URL) {
        self.photoToDelete = url
    }

    // Executar exclusão confirmada (somente local por enquanto)
    func deleteConfirmedPhoto() {
        guard let url = photoToDelete else { return }
        self.photoURLs.removeAll { $0 == url }
        self.photoToDelete = nil
    }

    // Salvar seleção de facilidades
    func saveFacilitiesSelection() async {
        do {
            let ids = selectedFacilities.map { $0.id }
            try await saveFacilitiesUseCase.execute(spaceId: spaceId, facilityIDs: ids)
            self.successMessage = "Facilidades salvas com sucesso."
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // Salvar todas as alterações (fotos + facilidades)
    func saveAll() async {
        print("🟡 saveAll() invoked for spaceId:", spaceId)
        errorMessage = nil
        successMessage = nil

        // Upload de fotos novas (se houver)
        await uploadPickedPhotosIfNeeded()

        // Montar o espaço atualizado e salvar tudo via caso de uso agregado
        let pricePerHour = Self.brlToDouble(pricePerHourBRL)
        let updatedSpace = ManagedSpace(
            id: spaceId,
            title: title,
            capacity: capacity,
            pricePerHour: pricePerHour,
            pricePerDay: Self.brlToDouble(pricePerDayBRL),
            description: descriptionText,
            isEnabled: isEnabledForBookings,
            isFullDay: isFullDay
        )
        do {
            let facilityIDs = selectedFacilities.map { $0.id }
            try await saveSpaceAllUseCase.execute(
                space: updatedSpace,
                pricePerDay: Self.brlToDouble(pricePerDayBRL),
                facilityIDs: facilityIDs,
                weekdays: selectedWeekdays,
                minDurationMinutes: minDurationMinutes,
                bufferMinutes: bufferMinutes,
                autoApprove: autoApproveBookings,
                rules: rules,

                startTime: isFullDay ? "00:00" : Self.string(from: startTime),
                endTime: isFullDay ? "23:59" : Self.string(from: endTime),
                isFullDay: isFullDay,
                email: email,
                ddd: ddd,
                phoneNumber: phoneNumber,
                companyName: companyName
            )
            self.successMessage = "Alterações salvas com sucesso."
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // Upload de fotos selecionadas (se houver)
    private func uploadPickedPhotosIfNeeded() async {
        guard !pickedItems.isEmpty else { return }
        print("📸 Uploading", pickedItems.count, "picked photos…")
        isUploading = true
        defer { isUploading = false }

        do {
            // Carregar os dados de cada item e enviar
            for item in pickedItems {
                if let data = try await item.loadTransferable(type: Data.self) {
                    let filename = UUID().uuidString + ".jpg"
                    let url = try await uploadPhotoUseCase.execute(data: data, filename: filename, spaceId: spaceId)
                    self.photoURLs.append(url)
                }
            }
            // Limpar seleção após upload
            pickedItems.removeAll()
            self.successMessage = "Fotos enviadas com sucesso."
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // Helpers de formatação
    static func brlString(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: NSNumber(value: value)) ?? "R$ 0,00"
    }

    static func brlToDouble(_ text: String) -> Double {
        // Remove currency symbol and whitespace
        let cleaned = text.replacingOccurrences(of: "R$", with: "").trimmingCharacters(in: .whitespaces)
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "pt_BR")
        
        if let number = formatter.number(from: cleaned) {
            return number.doubleValue
        }
        
        // Fallback for simple parsing if formatter fails (e.g. user typed "10.50" instead of "10,50")
        let standard = cleaned.replacingOccurrences(of: ",", with: ".")
        return Double(standard) ?? 0.0
    }

    private static func date(from timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }

    private static func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

