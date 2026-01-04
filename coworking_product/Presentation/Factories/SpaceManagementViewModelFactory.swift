//
//  SpaceManagementViewModelFactory.swift
//  coworking_product
//
//  Created by Fernando on 03/01/26.
//

import Foundation
@MainActor
func makeSpaceManagementViewModel(spaceId: String) -> CoHosterSpaceManagementViewModel {
    CoHosterSpaceManagementViewModel(
        spaceId: spaceId,
        fetchSpaceUseCase: StubFetchSpaceUseCase(),
        saveSpaceUseCase: StubSaveSpaceUseCase(),
        uploadPhotoUseCase: StubUploadPhotoUseCase(),
        saveFacilitiesUseCase: StubSaveFacilitiesUseCase(),
        saveAvailabilityUseCase: StubSaveAvailabilityUseCase(),
        saveRulesUseCase: StubSaveRulesUseCase(),
        updateSpaceFlagsUseCase: StubUpdateSpaceFlagsUseCase()
    )
}

// Stubs for all required use case protocols:
struct StubFetchSpaceUseCase: FetchSpaceUseCase {
    func execute(spaceId: String) async throws -> ManagedSpace {
        ManagedSpace(id: spaceId, title: "Stub", capacity: 1, pricePerHour: 0, description: "", isEnabled: true)
    }
}
struct StubSaveSpaceUseCase: SaveSpaceUseCase { func execute(_ space: ManagedSpace) async throws {} }
struct StubUploadPhotoUseCase: UploadPhotoUseCase { func execute(data: Data, filename: String, spaceId: String) async throws -> URL { URL(string: "https://example.com")! } }
struct StubSaveFacilitiesUseCase: SaveFacilitiesUseCase { func execute(spaceId: String, facilityIDs: [String]) async throws {} }
struct StubSaveAvailabilityUseCase: SaveAvailabilityUseCase { func execute(spaceId: String, weekdays: Set<Int>) async throws {} }
struct StubSaveRulesUseCase: SaveRulesUseCase { func execute(spaceId: String, minDurationMinutes: Int, bufferMinutes: Int) async throws {} }
struct StubUpdateSpaceFlagsUseCase: UpdateSpaceFlagsUseCase { func execute(spaceId: String, isEnabled: Bool, autoApprove: Bool) async throws {} }

