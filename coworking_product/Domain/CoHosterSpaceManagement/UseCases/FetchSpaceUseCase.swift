// Domain/CoHosterSpaceManagement/UseCases/FetchSpaceUseCase.swift
import Foundation

public protocol FetchSpaceUseCase {
    func execute(spaceId: String) async throws -> ManagedSpace
}
