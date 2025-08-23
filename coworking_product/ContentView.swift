import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                MainView() // Usuário já logado
            } else {
                LoginIntroView() // Tela de boas-vindas + botão de entrar
            }
        }
    }
}

struct LoginIntroView: View {
    @State private var goToLogin = false

    var body: some View {
        VStack {
            Spacer()

            Text("Bem vindo!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 4) {
                Text("Encontre o espaço")
                Text("ideal para")
                HStack {
                    Text("você")
                    Text("😉")
                }
            }
            .font(.title3)
            .foregroundColor(.gray)
            .multilineTextAlignment(.leading)

            Spacer()

            HStack {
                Spacer()
                Button(action: {
                    goToLogin = true
                }) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.black)
                }
                .padding()
            }
        }
        .padding()
        .navigationDestination(isPresented: $goToLogin) {
            LoginView()
        }
    }
}



#Preview {
    ContentView()
}
