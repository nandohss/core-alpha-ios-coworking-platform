// Presentation/CoHosterSpaceManagement/ViewModels/CoHosterSpaceManagementViewModel.swift
import Foundation

@MainActor
final class CoHosterSpaceManagementViewModel: ObservableObject {
    // MARK: - Publicados para a View
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var title: String = ""
    @Published var capacity: Int = 1
    @Published var pricePerHourBRL: String = ""
    @Published var descriptionText: String = ""
    @Published var isEnabledForBookings: Bool = true
    @Published var autoApproveBookings: Bool = false

    @Published var photoURLs: [URL] = []
    @Published var categories: [FacilityCategory] = []
    @Published var selectedFacilities: Set<Facility> = []
    @Published var selectedWeekdays: Set<Int> = []
    @Published var minDurationMinutes: Int = 60
    @Published var bufferMinutes: Int = 15

    // MARK: - Dependências (casos de uso do domínio)
    private let fetchSpaceUseCase: any FetchSpaceUseCase
    private let saveSpaceUseCase: any SaveSpaceUseCase
    private let uploadPhotoUseCase: any UploadPhotoUseCase
    private let saveFacilitiesUseCase: any SaveFacilitiesUseCase
    private let saveAvailabilityUseCase: any SaveAvailabilityUseCase
    private let saveRulesUseCase: any SaveRulesUseCase
    private let updateSpaceFlagsUseCase: any UpdateSpaceFlagsUseCase

    private let spaceId: String

    init(
        spaceId: String,
        fetchSpaceUseCase: any FetchSpaceUseCase,
        saveSpaceUseCase: any SaveSpaceUseCase,
        uploadPhotoUseCase: any UploadPhotoUseCase,
        saveFacilitiesUseCase: any SaveFacilitiesUseCase,
        saveAvailabilityUseCase: any SaveAvailabilityUseCase,
        saveRulesUseCase: any SaveRulesUseCase,
        updateSpaceFlagsUseCase: any UpdateSpaceFlagsUseCase
    ) {
        self.spaceId = spaceId
        self.fetchSpaceUseCase = fetchSpaceUseCase
        self.saveSpaceUseCase = saveSpaceUseCase
        self.uploadPhotoUseCase = uploadPhotoUseCase
        self.saveFacilitiesUseCase = saveFacilitiesUseCase
        self.saveAvailabilityUseCase = saveAvailabilityUseCase
        self.saveRulesUseCase = saveRulesUseCase
        self.updateSpaceFlagsUseCase = updateSpaceFlagsUseCase
    }

    // Carregar dados do espaço
    func load() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            let space = try await fetchSpaceUseCase.execute(spaceId: spaceId)
            self.title = space.title
            self.capacity = space.capacity
            self.pricePerHourBRL = Self.brlString(from: space.pricePerHour)
            self.descriptionText = space.description
            self.isEnabledForBookings = space.isEnabled
            // Carregar demais dados conforme necessidade
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
        let digits = text.filter({ "0123456789".contains($0) })
        let cents = Double(digits) ?? 0
        return cents / 100.0
    }
}
