import SwiftUI

// Simple shimmer effect
fileprivate struct ShimmerView: View {
    @State private var start: CGFloat = -1
    @State private var end: CGFloat = 0
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.gray.opacity(0.2),
                Color.gray.opacity(0.35),
                Color.gray.opacity(0.2)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .mask(
            Rectangle()
                .fill(
                    LinearGradient(colors: [.black.opacity(0.0), .black, .black.opacity(0.0)], startPoint: .leading, endPoint: .trailing)
                )
                .offset(x: UIScreen.main.bounds.width * start)
        )
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                start = 1.5
            }
        }
    }
}

fileprivate extension View {
    func shimmered() -> some View {
        self.overlay(ShimmerView().blendMode(.plusLighter))
    }
}

// MARK: - ViewModel
@MainActor
class CoworkingViewModel: ObservableObject {
    @Published var coworkings: [Coworking] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    func fetchCoworkings() async {
        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/spaces") else {
            self.errorMessage = "URL inválida"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 JSON recebido da API:\n\(jsonString)")
            }

            let decoded = try JSONDecoder().decode([Coworking].self, from: data)
            coworkings = decoded

        } catch {
            print("❌ Erro ao carregar ou decodificar coworkings:", error)
            errorMessage = "Erro ao carregar coworkings: \(error.localizedDescription)"
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = CoworkingViewModel()
    @State private var searchText: String = ""
    @State private var selectedCategory: FormsConstants.CategoriaPrincipal = .escritorio

    // Lista filtrada com base na categoria e na busca
    var filteredCoworkings: [Coworking] {
        guard let categoriasSelecionadas = FormsConstants.categorias[selectedCategory.rawValue] else {
            return []
        }

        return viewModel.coworkings.filter { coworking in
            categoriasSelecionadas.contains(coworking.subcategoria) &&
            (searchText.isEmpty ||
             coworking.nome.localizedCaseInsensitiveContains(searchText) ||
             coworking.cidade.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top fixed area
                TopBarView(searchText: $searchText)
                    .animation(nil, value: searchText)
                    .background(Color(.systemBackground))
                    .overlay(Divider().opacity(0.5), alignment: .bottom)
                    .zIndex(2)

                // Fixed category menu (does not scroll)
                CategoryMenuView(
                    selected: $selectedCategory,
                    categories: FormsConstants.CategoriaPrincipal.allCases
                )
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .overlay(Divider().opacity(0.5), alignment: .bottom)
                .zIndex(1)

                // Scrollable content area
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            // Skeleton placeholders while loading (with shimmer)
                            ForEach(0..<6, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 180)
                                    .overlay(
                                        VStack(alignment: .leading, spacing: 12) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(height: 100)

                                            HStack(spacing: 12) {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 120, height: 14)
                                                Spacer()
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 80, height: 14)
                                            }

                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 160, height: 12)
                                        }
                                        .padding()
                                    )
                                    .redacted(reason: .placeholder)
                                    .shimmered()
                            }
                        } else if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            if filteredCoworkings.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .resizable()
                                        .frame(width: 72, height: 72)
                                        .foregroundColor(.gray.opacity(0.3))
                                        .rotationEffect(.degrees(10))
                                        .shadow(radius: 4)

                                    Text("Nenhum espaço encontrado")
                                        .font(.headline)
                                        .foregroundColor(.gray)

                                    Text("Tente outro nome de cidade, bairro ou coworking.")
                                        .font(.subheadline)
                                        .foregroundColor(.gray.opacity(0.7))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                .padding(.top, 24)
                                .padding(.horizontal)
                            } else {
                                ForEach(filteredCoworkings) { coworking in
                                    NavigationLink {
                                        CoworkingDetailView(
                                            coworking: coworking,
                                            facilities: coworking.facilities,
                                            selectedTab: $selectedTab
                                        )
                                    } label: {
                                        CoworkingCardView(
                                            imageURL: coworking.imagemUrl ?? "",
                                            name: coworking.nome,
                                            location: coworking.cidade,
                                            address: coworking.bairro,
                                            price: String(format: "R$ %.2f / hora", coworking.precoHora ?? 0)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }

                            Spacer().frame(height: 32)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom)
                    .refreshable {
                        await viewModel.fetchCoworkings()
                    }
                }
            }
            .task {
                await viewModel.fetchCoworkings()
            }
            .background(Color(.systemGray6))
            .ignoresSafeArea(edges: .bottom)
        }
    }
}

