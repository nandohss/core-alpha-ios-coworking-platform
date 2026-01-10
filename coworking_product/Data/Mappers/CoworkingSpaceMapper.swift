import Foundation

struct CoworkingSpaceMapper {
    static func toDomain(dto: CoworkingSpaceDTO) -> CoworkingSpace {
        let address = CoworkingAddress(
            street: dto.street,
            number: dto.number,
            complement: dto.complement,
            district: dto.district,
            city: dto.city,
            state: dto.state,
            country: dto.country
        )
        
        let pricing = CoworkingPricing(
            hourlyRate: dto.precoHora ?? 0.0,
            dailyRate: dto.precoDia,
            isFullDay: dto.isFullDay ?? false
        )
        
        let availability = CoworkingAvailability(
            startHour: dto.horaInicio,
            endHour: dto.horaFim,
            weekdays: dto.diasSemana
        )
        
        return CoworkingSpace(
            id: dto.spaceId,
            name: dto.name,
            description: dto.descricao ?? "",
            category: dto.categoria ?? "",
            subcategory: dto.subcategoria ?? "",
            imageUrl: dto.imagemUrl,
            address: address,
            pricing: pricing,
            availability: availability,
            facilities: dto.amenities ?? [],
            rules: dto.regras,
            hosterId: dto.hoster
        )
    }
}
