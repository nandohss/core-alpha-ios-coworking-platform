//
//  ReservationModel.swift
//  coworking_product
//
//  Created by Fernando on 06/07/25.
//

import Foundation
import SwiftUI
import CoreImage.CIFilterBuiltins

struct Reservation: Identifiable {
    let id = UUID()
    let coworkingName: String
    let imageName: String
    let date: Date
    let hours: [Int]
    let price: Double

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date)
    }

    var formattedHours: String {
        hours.map { "\($0)h" }.joined(separator: ", ")
    }

    func generateQRCodeImage() -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        let content = """
        Reserva: \(coworkingName)
        Data: \(formattedDate)
        Horas: \(formattedHours)
        Total: R$ \(String(format: "%.2f", price))
        """

        let data = Data(content.utf8)
        filter.setValue(data, forKey: "inputMessage")

        if let outputImage = filter.outputImage {
            let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
            if let cgimg = context.createCGImage(transformed, from: transformed.extent) {
                return UIImage(cgImage: cgimg)
            }
        }

        return nil
    }
}
