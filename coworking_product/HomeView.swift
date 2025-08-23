
import SwiftUI

// MARK: - Model
struct Coworking: Identifiable, Decodable {
    let id: String
    let nome: String
    let cidade: String
    let imagemUrl: String
    let precoHora: Double
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
            let decoded = try JSONDecoder().decode([Coworking].self, from: data)
            coworkings = decoded
        } catch {
            errorMessage = "Erro ao carregar coworkings: \(error.localizedDescription)"
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @StateObject private var viewModel = CoworkingViewModel()

    struct Category: Identifiable {
        let id = UUID()
        let name: String
        let icon: String
    }

    @State private var selectedCategory = "Corporativo"

    let categories: [Category] = [
        Category(name: "Corporativo", icon: "briefcase.fill"),
        Category(name: "Tech", icon: "desktopcomputer"),
        Category(name: "Educação", icon: "book.closed.fill"),
        Category(name: "Eventos", icon: "calendar"),
        Category(name: "Outros", icon: "ellipsis")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopBarView()
                CategoryMenuView(selected: $selectedCategory, categories: categories)

                ZStack {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.coworkings) { coworking in
                                NavigationLink {
                                    CoworkingDetailView(
                                        coworking: coworking,
                                        facilities: []
                                    )
                                } label: {
                                    CoworkingCardView(
                                        imageURL: coworking.imagemUrl,
                                        name: coworking.nome,
                                        location: coworking.cidade,
                                        address: coworking.cidade,
                                        price: "R$ \(coworking.precoHora, specifier: "%.2f") / hora"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }

                    if viewModel.isLoading {
                        ProgressView("Carregando espaços...")
                            .padding()
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
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

#Preview {
    MainView()
}
