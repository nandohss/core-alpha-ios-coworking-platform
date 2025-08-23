import SwiftUI

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
                TopBarView(searchText: $searchText)
                    .animation(nil, value: searchText)

                // Categoria por ícone (passando enum diretamente)
                CategoryMenuView(
                    selected: $selectedCategory,
                    categories: FormsConstants.CategoriaPrincipal.allCases
                )

                if viewModel.isLoading {
                    ProgressView("Carregando espaços...")
                        .padding()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
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
                                .padding(.top, 40)
                                .padding(.horizontal)
                            } else {
                                ForEach(filteredCoworkings) { coworking in
                                    NavigationLink {
                                        CoworkingDetailView(
                                            coworking: coworking,
                                            facilities: coworking.facilities
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
                        .padding()
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
