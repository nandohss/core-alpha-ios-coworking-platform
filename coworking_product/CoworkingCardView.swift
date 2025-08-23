import SwiftUI

struct CoworkingCardView: View {
    let imageURL: String
    let name: String
    let location: String
    let address: String
    let price: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Imagem
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .clipped()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                case .failure:
                    Color.gray
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .overlay(Text("Erro ao carregar imagem").foregroundColor(.white))
                        .clipped()
                @unknown default:
                    EmptyView()
                }
            }

            // Texto
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                Text(location)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(address)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Text(price)
                    .font(.subheadline)
                    .bold()
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .frame(maxWidth: UIScreen.main.bounds.width * 0.96)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
