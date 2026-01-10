import SwiftUI

struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                MainView()
            } else {
                LoginIntroView()
            }
        }
    }
}

struct LoginIntroView: View {
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore = false
    @State private var animStep = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Bem vindo!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .opacity(animStep >= 1 ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: animStep)

            // Texto sequencial
            // Composição usando + para manter o fluxo de parágrafo
            (Text("Encontre o espaço certo para trabalhar, ")
                .foregroundColor(animStep >= 2 ? .gray : .clear) +
             Text("atender ")
                .foregroundColor(animStep >= 3 ? .gray : .clear) +
             Text("ou reunir ")
                .foregroundColor(animStep >= 4 ? .gray : .clear) +
             Text("\n— quando você precisar. 😉") // Quebra de linha sugerida para a parte final
                .foregroundColor(animStep >= 5 ? .gray : .clear))
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.5), value: animStep)

            Spacer()

            HStack {
                Spacer()
                Button(action: {
                    withAnimation {
                         hasLaunchedBefore = true
                    }
                }) {
                    Image(systemName: "arrow.right")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.black)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding()
                .opacity(animStep >= 5 ? 1 : 0)
                .scaleEffect(animStep >= 5 ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animStep)
            }
        }
        .padding()
        .onAppear {
            runAnimationSequence()
        }
    }

    func runAnimationSequence() {
        // Step 1: Bem vindo
        withAnimation { animStep = 1 }

        // Sequência temporal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation { animStep = 2 } // Trabalhar
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { animStep = 3 } // Atender
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation { animStep = 4 } // Reunir
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation { animStep = 5 } // Final
        }
    }
}



#Preview {
    ContentView()
}
