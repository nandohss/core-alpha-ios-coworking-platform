import Foundation

public protocol FetchFacilitiesUseCase {
    func execute() async throws -> [Facility]
}
