//
//  SplashScreenView.swift
//  coworking_product
//
//  Created by Fernando on 03/12/25.
//


import SwiftUI

struct SplashScreenView: View {
    // Closure to notify when splash finishes
    var onFinish: (() -> Void)? = nil
    
    // Estados para controlar a animação
    @State private var isActive = false
    @State private var opacity = 0.0
    @State private var scale = 0.8
    @State private var showGreyCircle = false
    @State private var showWhiteDot = false
    
    var body: some View {
        ZStack {
            // 1. Fundo Preto
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // 2. O Ícone Gráfico
                ZStack {
                    // Círculo Cinza (O "corpo" ou fundo do ícone)
                    if showGreyCircle {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 60, height: 60)
                            .transition(.scale.animation(.spring(response: 0.4, dampingFraction: 0.6)))
                    }
                    
                    // As duas barras laterais (Pillars)
                    HStack(spacing: 55) { // Espaçamento para caber o círculo no meio
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 25, height: 90)
                        
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 25, height: 90)
                    }
                    
                    // Ponto Branco (O centro/cabeça)
                    if showWhiteDot {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(y: -10) // Ajuste levemente para cima se parecer uma "cabeça", ou remova o offset para ser centralizado
                            .transition(.scale.animation(.bouncy(duration: 0.3)))
                    }
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                // 3. O Texto "Hubros"
                Text("Hubros")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Sequência de Animação
            
            // Passo 1: Surge o Logo e Texto base
            withAnimation(.easeIn(duration: 0.7)) {
                self.scale = 1.0
                self.opacity = 1.0
            }
            
            // Passo 2: O Círculo Cinza aparece (0.5s depois)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.showGreyCircle = true
                }
            }
            
            // Passo 3: O Ponto Branco aparece (0.8s depois)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    self.showWhiteDot = true
                }
            }
            
            // Passo 4: Chamar onFinish (2.5s depois)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    self.isActive = true
                    onFinish?()
                }
            }
        }
    }
}

// Tela de exemplo para simular o App abrindo
struct Content2View: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            Text("Bem-vindo ao Hubros")
                .font(.title)
                .foregroundColor(.black)
        }
    }
}

#Preview {
    SplashScreenView()
}
