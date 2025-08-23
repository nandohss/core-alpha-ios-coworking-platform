import SwiftUI

struct CoworkingCardView: View {
    let imageURL: String
    let name: String
    let location: String
    let address: String
    let price: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 150)
            .clipped()

            Text(name)
                .font(.headline)
            Text(location)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(price)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
