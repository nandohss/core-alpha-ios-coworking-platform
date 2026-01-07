//
//  FacilityItem.swift
//  coworking_product
//
//  Created by Fernando on 05/07/25.
//

import Foundation

struct FacilityItem: Identifiable {
    let id: UUID
    let label: String
    let icon: String

    init(from name: String) {
        self.id = UUID()
        self.label = name

        switch name.lowercased() {
        case "wi-fi":
            self.icon = "wifi"
        case "café":
            self.icon = "cup.and.saucer"
        case "projetor":
            self.icon = "video"
        case "ar-condicionado":
            self.icon = "wind"
        case "lousa":
            self.icon = "rectangle.and.pencil.and.ellipsis"
        case "sala de reunião":
            self.icon = "person.2.fill"
        default:
            self.icon = "questionmark"
        }
    }

    // Conveniências para integração com o domínio
    init(from facility: Facility) {
        if let symbol = facility.systemImage {
            self.init(label: facility.name, icon: symbol)
        } else {
            self.init(from: facility.name)
        }
    }

    init(label: String, icon: String) {
        self.id = UUID()
        self.label = label
        self.icon = icon
    }
}
