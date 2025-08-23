import SwiftUI

struct MainView: View {
    @State private var selectedTab = 2
    @State private var hideTabBar = false
    @State private var isLoadingHoster = true

    @AppStorage("isHoster") private var isHoster: Bool = false
    @AppStorage("userId") private var userId: String = ""

    var body: some View {
        ZStack {
            if selectedTab == 0 && isHoster && !isLoadingHoster {
                // 🔁 Exibe a tela com menu local
                NavigationStack {
                    MySpacesView(selectedTabMain: $selectedTab)
                }
            } else {
                // 🔁 Exibe o menu principal do app
                TabView(selection: $selectedTab) {
                    // Aba 0 – CoHoster ou BecomeCoHoster
                    Group {
                        if isLoadingHoster {
                            ProgressView("Carregando...")
                        } else if !isHoster {
                            BecomeCoHosterView(hideTabBar: $hideTabBar, selectedTab: $selectedTab)
                        } else {
                            // Caso `isHoster == true`, o conteúdo dessa aba será sobrescrito por `MySpacesView` acima.
                            Color.clear
                        }
                    }
                    .tabItem {
                        Image(systemName: "building.2.crop.circle")
                        Text("CoHoster")
                    }
                    .tag(0)
                    .onAppear {
                        print("🔄 Verificando isHoster para userId =", userId)
                        verificarHoster()
                    }

                    // Aba 1 – Favoritos
                    Text("Favoritos")
                        .tabItem {
                            Image(systemName: "heart")
                            Text("Favoritos")
                        }
                        .tag(1)

                    // Aba 2 – Início
                    HomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Início")
                        }
                        .tag(2)

                    // Aba 3 – Reservas
                    MyReservationsView()
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("Reservas")
                        }
                        .tag(3)

                    // Aba 4 – Perfil
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Perfil")
                        }
                        .tag(4)
                }
                .accentColor(.black)
                .opacity(hideTabBar ? 0 : 1)
            }
        }
    }

    // MARK: - Verificação de status hoster
    func verificarHoster() {
        guard !userId.isEmpty else {
            print("⚠️ userId ainda não definido")
            isLoadingHoster = false
            return
        }

        guard let url = URL(string: "https://i6yfbb45xc.execute-api.sa-east-1.amazonaws.com/pro/users/\(userId)") else {
            print("❌ URL inválida")
            isLoadingHoster = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                DispatchQueue.main.async { isLoadingHoster = false }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                print("📥 JSON recebido:", json ?? "nil")

                if let hosterStatus = json?["isHoster"] as? Bool {
                    DispatchQueue.main.async {
                        self.isHoster = hosterStatus
                        self.isLoadingHoster = false
                        print("✅ isHoster atualizado dinamicamente:", hosterStatus)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoadingHoster = false
                        print("❌ Campo isHoster não encontrado ou inválido")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingHoster = false
                    print("❌ Erro ao decodificar JSON:", error.localizedDescription)
                }
            }
        }.resume()
    }
}
