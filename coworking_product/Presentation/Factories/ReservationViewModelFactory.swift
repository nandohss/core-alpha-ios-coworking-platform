
import Foundation

@MainActor
struct ReservationViewModelFactory {
    static func makeDateSelectionViewModel(space: CoworkingSpace) -> DateSelectionViewModel {
        // Here we could inject distinct repositories or configurations if needed
        let repository = CoworkerReservationsRepositoryImpl()
        let useCase = RealCheckReservationAvailabilityUseCase(repository: repository)
        
        return DateSelectionViewModel(space: space, checkAvailabilityUseCase: useCase)
    }
}
