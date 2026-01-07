//
//  SpaceManagementViewModelFactory.swift
//  coworking_product
//
//  Created by Fernando on 03/01/26.
//

import Foundation

// baseURL: URL do seu backend, ex.: URL(string: "https://api.seuservidor.com")!
// authTokenProvider: closure que retorna o token de autenticação para requisições

@MainActor
func makeSpaceManagementViewModel(spaceId: String) -> CoHosterSpaceManagementViewModel {
    fatalError("This factory overload without backend dependencies has been removed. Use the overload that injects authTokenProvider/baseURL.")
}

@MainActor
func makeSpaceManagementViewModel(
    spaceId: String,
    authTokenProvider: @escaping () -> String?
) -> CoHosterSpaceManagementViewModel {
    print("🔧 Injecting baseURL:", AppConfig.apiBaseURL.absoluteString)
    let repository = SpaceManagementRepositoryImpl(baseURL: AppConfig.apiBaseURL, authTokenProvider: authTokenProvider)
    return CoHosterSpaceManagementViewModel(
        spaceId: spaceId,
        fetchSpaceUseCase: RealFetchSpaceUseCase(repository: repository),
        fetchFacilitiesUseCase: RealFetchFacilitiesUseCase(repository: repository),
        saveSpaceUseCase: RealSaveSpaceUseCase(repository: repository),
        uploadPhotoUseCase: NoopUploadPhotoUseCase(),
        saveFacilitiesUseCase: NoopSaveFacilitiesUseCase(),
        saveAvailabilityUseCase: NoopSaveAvailabilityUseCase(),
        saveRulesUseCase: NoopSaveRulesUseCase(),
        updateSpaceFlagsUseCase: NoopUpdateSpaceFlagsUseCase(),
        saveSpaceAllUseCase: RealSaveSpaceAllUseCase(repository: repository)
    )
}

@MainActor
func makeSpaceManagementViewModel(
    spaceId: String,
    baseURL: URL,
    authTokenProvider: @escaping () -> String?
) -> CoHosterSpaceManagementViewModel {
    let repository = SpaceManagementRepositoryImpl(baseURL: baseURL, authTokenProvider: authTokenProvider)
    return CoHosterSpaceManagementViewModel(
        spaceId: spaceId,
        fetchSpaceUseCase: RealFetchSpaceUseCase(repository: repository),
        fetchFacilitiesUseCase: RealFetchFacilitiesUseCase(repository: repository),
        saveSpaceUseCase: RealSaveSpaceUseCase(repository: repository),
        uploadPhotoUseCase: NoopUploadPhotoUseCase(),
        saveFacilitiesUseCase: NoopSaveFacilitiesUseCase(),
        saveAvailabilityUseCase: NoopSaveAvailabilityUseCase(),
        saveRulesUseCase: NoopSaveRulesUseCase(),
        updateSpaceFlagsUseCase: NoopUpdateSpaceFlagsUseCase(),
        saveSpaceAllUseCase: RealSaveSpaceAllUseCase(repository: repository)
    )
    // TODO: Injetar SaveSpaceAllUseCase no ViewModel quando o initializer aceitar a dependência agregada.
}

struct RealFetchSpaceUseCase: FetchSpaceUseCase {
    let repository: SpaceManagementRepository
    func execute(spaceId: String) async throws -> ManagedSpace {
        try await repository.fetchSpace(spaceId: spaceId)
    }
}
struct RealSaveSpaceUseCase: SaveSpaceUseCase {
    let repository: SpaceManagementRepository
    func execute(_ space: ManagedSpace) async throws {
        try await repository.saveSpace(space)
    }
}

struct RealFetchFacilitiesUseCase: FetchFacilitiesUseCase {
    let repository: SpaceManagementRepository
    func execute() async throws -> [Facility] {
        try await repository.fetchFacilities()
    }
}

// Temporary no-op implementations until real use cases are available

struct NoopUploadPhotoUseCase: UploadPhotoUseCase {
    func execute(data: Data, filename: String, spaceId: String) async throws -> URL { return URL(string: "about:blank")! }
}
struct NoopSaveFacilitiesUseCase: SaveFacilitiesUseCase {
    func execute(spaceId: String, facilityIDs: [String]) async throws { }
}
struct NoopSaveAvailabilityUseCase: SaveAvailabilityUseCase {
    func execute(spaceId: String, weekdays: Set<Int>) async throws { }
}
struct NoopSaveRulesUseCase: SaveRulesUseCase {
    func execute(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws { }
}
struct NoopUpdateSpaceFlagsUseCase: UpdateSpaceFlagsUseCase {
    func execute(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws { }
}
