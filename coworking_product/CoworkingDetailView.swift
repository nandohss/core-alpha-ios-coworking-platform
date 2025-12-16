import SwiftUI

struct CoworkingDetailView: View {
    var coworking: Coworking
    var facilities: [String]
    @Binding var selectedTab: Int

    @State private var isFavorited = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Imagem com largura controlada
                        AsyncImage(url: URL(string: coworking.imagemUrl ?? "")) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: geometry.size.width, height: 250)
                                    .background(Color.gray.opacity(0.2))
                                    .clipped()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geometry.size.width, height: 250)
                                    .clipped()
                            case .failure:
                                Color.gray
                                    .frame(width: geometry.size.width, height: 250)
                                    .overlay(Text("Erro ao carregar imagem").foregroundColor(.white))
                                    .clipped()
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // Conteúdo
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                Text(coworking.nome)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)

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
                                // Linha 1: Rua e número (quando existirem)
                                if let street = coworking.street, !street.isEmpty {
                                    HStack(spacing: 4) {
                                        Text(street)
                                            .font(.subheadline)
                                        if let number = coworking.number, !number.isEmpty {
                                            Text(", \(number)")
                                                .font(.subheadline)
                                        }
                                    }
                                }
                                // Linha 2: Cidade e Bairro
                                HStack(spacing: 6) {
                                    Text(coworking.cidade)
                                        .font(.subheadline)
                                    if !coworking.bairro.isEmpty {
                                        Text("·").foregroundColor(.gray)
                                        Text(coworking.bairro)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }

                            Text(coworking.descricao)
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

                            Divider().padding(.vertical, 10)

                            // Categoria e Subcategoria
                            if !coworking.categoria.isEmpty || !coworking.subcategoria.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Categoria")
                                        .font(.subheadline).fontWeight(.medium)
                                    HStack(spacing: 8) {
                                        if !coworking.categoria.isEmpty {
                                            Text(coworking.categoria)
                                                .font(.footnote)
                                                .padding(.vertical, 4).padding(.horizontal, 8)
                                                .background(Color.gray.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                        if !coworking.subcategoria.isEmpty {
                                            Text(coworking.subcategoria)
                                                .font(.footnote)
                                                .padding(.vertical, 4).padding(.horizontal, 8)
                                                .background(Color.gray.opacity(0.15))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                            }

                            // Regras
                            if let regras = coworking.regras, !regras.isEmpty {
                                Divider().padding(.vertical, 10)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Regras")
                                        .font(.subheadline).fontWeight(.medium)
                                    Text(regras)
                                        .font(.footnote)
                                        .foregroundColor(.gray)
                                }
                            }

                        }
                        .padding()
                        .frame(width: geometry.size.width, alignment: .leading)
                        .background(Color.white)
                    }
                    .padding(.bottom, 120)
                }

                // Botão fixo
                HStack {
                    Text(String(format: "R$ %.2f / hora", coworking.precoHora ?? 0))
                        .font(.title3)
                        .fontWeight(.bold)

                    Spacer()

                    NavigationLink(destination: DateSelectionView(coworking: coworking, selectedTab: $selectedTab)) {
                        Text("Reservar")
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .frame(width: geometry.size.width)
                .background(.ultraThinMaterial)
            }
            .navigationTitle(coworking.nome)
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(edges: .top)
            .onAppear {
                print("Facilities recebidas:", facilities)
            }
        }
    }
}

private func formatPhone(_ digits: String) -> String {
    let d = digits.filter { $0.isNumber }
    if d.count >= 11 {
        let ddd = d.prefix(2)
        let mid = d.dropFirst(2).prefix(5)
        let end = d.suffix(4)
        return "(\(ddd)) \(mid)-\(end)"
    } else if d.count >= 10 {
        let ddd = d.prefix(2)
        let mid = d.dropFirst(2).prefix(4)
        let end = d.suffix(4)
        return "(\(ddd)) \(mid)-\(end)"
    } else {
        return d
    }
}
