import Foundation

public struct CoworkingSpace: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let category: String
    public let subcategory: String
    public let imageUrl: String?
    
    // Grouped Properties
    public let address: CoworkingAddress
    public let pricing: CoworkingPricing
    public let availability: CoworkingAvailability
    public let facilities: [String]
    public let rules: String?
    public let hosterId: String?
    
    public init(
        id: String,
        name: String,
        description: String,
        category: String,
        subcategory: String,
        imageUrl: String?,
        address: CoworkingAddress,
        pricing: CoworkingPricing,
        availability: CoworkingAvailability,
        facilities: [String],
        rules: String?,
        hosterId: String?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.subcategory = subcategory
        self.imageUrl = imageUrl
        self.address = address
        self.pricing = pricing
        self.availability = availability
        self.facilities = facilities
        self.rules = rules
        self.hosterId = hosterId
    }
}

public struct CoworkingAddress: Equatable {
    public let street: String?
    public let number: String?
    public let complement: String?
    public let district: String
    public let city: String
    public let state: String?
    public let country: String?
    
    public init(street: String?, number: String?, complement: String?, district: String, city: String, state: String?, country: String?) {
        self.street = street
        self.number = number
        self.complement = complement
        self.district = district
        self.city = city
        self.state = state
        self.country = country
    }
}

public struct CoworkingPricing: Equatable {
    public let hourlyRate: Double
    public let dailyRate: Double?
    public let isFullDay: Bool
    
    public init(hourlyRate: Double, dailyRate: Double?, isFullDay: Bool) {
        self.hourlyRate = hourlyRate
        self.dailyRate = dailyRate
        self.isFullDay = isFullDay
    }
}

public struct CoworkingAvailability: Equatable {
    public let startHour: String?
    public let endHour: String?
    public let weekdays: [String]?
    
    public init(startHour: String?, endHour: String?, weekdays: [String]?) {
        self.startHour = startHour
        self.endHour = endHour
        self.weekdays = weekdays
    }
}
