
import SwiftUI

struct CoworkingDetailView: View {
    var coworking: Coworking
    var facilities: [String]

    @State private var isFavorited = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    AsyncImage(url: URL(string: coworking.imagemUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView().frame(height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                        case .failure:
                            Color.gray
                                .frame(height: 250)
                                .overlay(Text("Erro ao carregar imagem").foregroundColor(.white))
                        @unknown default:
                            EmptyView()
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(coworking.nome)
                                .font(.title2)
                                .fontWeight(.bold)

                            Spacer()

                            Button(action: {
                                isFavorited.toggle()
                            }) {
                                Image(systemName: isFavorited ? "heart.fill" : "heart")
                                    .foregroundColor(isFavorited ? .red : .gray)
                                    .font(.title2)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(coworking.cidade)
                                .font(.subheadline)
                            Text(coworking.cidade)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Text("Descrição não disponível.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.top, 8)

                        Divider().padding(.vertical, 10)

                        Text("O que esse espaço possui")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(facilities.map { FacilityItem(from: $0) }) { facility in
                                    FacilityView(facility: facility)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding()
                    .background(Color.white)
                }
            }

            HStack {
                Text(String(format: "R$ %.2f / hora", coworking.precoHora))
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                NavigationLink(destination: DateSelectionView(coworking: coworking)) {
                    Text("Reservar")
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(Color.black)
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle(coworking.nome)
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea(edges: .top)
    }
}
