import SwiftUI

// MARK: - Shape com raio diferente por canto (para arredondar só os cantos externos)
struct CornerRadiiShape: Shape {
    var topLeft: CGFloat
    var topRight: CGFloat
    var bottomLeft: CGFloat
    var bottomRight: CGFloat

    var animatableData: AnimatablePair<
        AnimatablePair<CGFloat, CGFloat>,
        AnimatablePair<CGFloat, CGFloat>
    > {
        get { .init(.init(topLeft, topRight), .init(bottomLeft, bottomRight)) }
        set {
            topLeft = newValue.first.first
            topRight = newValue.first.second
            bottomLeft = newValue.second.first
            bottomRight = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let tl = min(min(topLeft, rect.width/2), rect.height/2)
        let tr = min(min(topRight, rect.width/2), rect.height/2)
        let bl = min(min(bottomLeft, rect.width/2), rect.height/2)
        let br = min(min(bottomRight, rect.width/2), rect.height/2)

        var p = Path()

        p.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))

        // Top
        p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        if tr > 0 {
            p.addArc(
                center: CGPoint(x: rect.maxX - tr, y: rect.minY + tr),
                radius: tr,
                startAngle: .degrees(-90),
                endAngle: .degrees(0),
                clockwise: false
            )
        }

        // Right
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        if br > 0 {
            p.addArc(
                center: CGPoint(x: rect.maxX - br, y: rect.maxY - br),
                radius: br,
                startAngle: .degrees(0),
                endAngle: .degrees(90),
                clockwise: false
            )
        }

        // Bottom
        p.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        if bl > 0 {
            p.addArc(
                center: CGPoint(x: rect.minX + bl, y: rect.maxY - bl),
                radius: bl,
                startAngle: .degrees(90),
                endAngle: .degrees(180),
                clockwise: false
            )
        }

        // Left
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        if tl > 0 {
            p.addArc(
                center: CGPoint(x: rect.minX + tl, y: rect.minY + tl),
                radius: tl,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        }

        p.closeSubpath()
        return p
    }
}

// MARK: - Splash
struct SplashScreenView: View {
    var onFinish: (() -> Void)? = nil

    @State private var showPillars = false
    @State private var pillarsGrow: CGFloat = 0.0
    @State private var bottomRadius: CGFloat = 0.0

    @State private var textReveal: CGFloat = 0.0

    // torso cresce por recorte (mask) 0..1
    @State private var torsoFill: CGFloat = 0.0
    @State private var torsoColorIsWhite = false

    @State private var showHead = false
    @State private var finishWorkItem: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let unit = min(w, h) // base de escala

            // Tamanhos (reduzidos e proporcionais)
            let pillarWidth  = unit * 0.035          // ~ 30 em telas comuns (ainda mais fino)
            let pillarHeight = unit * 0.18          // ~ 110
            let gap          = unit * 0.115          // + espaçamento entre pilares para dar mais folga ao torso
            let outerRadius  = pillarWidth * 1.0    // cantos externos bem mais arredondados
            let innerBottomMax = pillarWidth * 0.15  // limita arredondamento dos cantos internos inferiores
            let iconWidth    = pillarWidth * 2 + gap   // largura total do conjunto (pilares + vão)

            let circleSize   = unit * 0.09          // torso/cabeça ~ 50 (menor)
            let iconSpacing  = unit * 0.05          // espaçamento entre ícone e texto

            let textSize     = unit * 0.12          // ~ 48
            let topPadding   = unit * 0.10          // posicionamento vertical

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: iconSpacing) {
                    // Ícone
                    ZStack {
                        if showPillars {
                            HStack(spacing: gap) {
                                // Pilar esquerdo (arredonda só cantos externos)
                                CornerRadiiShape(
                                    topLeft: outerRadius,
                                    topRight: 0,
                                    bottomLeft: bottomRadius,
                                    bottomRight: min(bottomRadius, innerBottomMax)
                                )
                                .fill(Color.white)
                                .frame(width: pillarWidth, height: pillarHeight)
                                // Base fixa, cresce para cima
                                .scaleEffect(x: 1, y: pillarsGrow, anchor: .bottom)

                                // Pilar direito
                                CornerRadiiShape(
                                    topLeft: 0,
                                    topRight: outerRadius,
                                    bottomLeft: min(bottomRadius, innerBottomMax),
                                    bottomRight: bottomRadius
                                )
                                .fill(Color.white)
                                .frame(width: pillarWidth, height: pillarHeight)
                                .scaleEffect(x: 1, y: pillarsGrow, anchor: .bottom)
                            }
                            // Anti-aliasing mais “limpo”
                            .drawingGroup()
                        }

                        // Torso (cresce por recorte, não por escala)
                        Circle()
                            .fill(torsoColorIsWhite ? Color.white : Color.gray.opacity(0.65))
                            .frame(width: circleSize, height: circleSize)
                            .mask(
                                Rectangle()
                                    .frame(width: circleSize, height: circleSize * torsoFill)
                                    .frame(maxHeight: .infinity, alignment: Alignment.bottom)
                            )
                            .offset(y: -unit * 0.015) // respiro para cima em relação ao centro dos pilares
                            .opacity(torsoFill > 0 ? 1 : 0)

                        // Cabeça
                        if showHead {
                            Circle()
                                .fill(Color.white)
                                .frame(width: circleSize, height: circleSize)
                                .offset(y: -(pillarHeight / 2 + circleSize / 2 + unit * 0.01))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(width: iconWidth)

                    // Texto "Hubros" com revelação de baixo para cima (máscara correta)
                    Text("Hubros")
                        .font(.system(size: textSize, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .mask(
                            GeometryReader { tgeo in
                                Rectangle()
                                    .frame(height: tgeo.size.height * textReveal)
                                    .frame(maxHeight: .infinity, alignment: Alignment.bottom)
                            }
                        )
                        .opacity(textReveal == 0 ? 0 : 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .onAppear { runTimeline() }
            .onDisappear {
                finishWorkItem?.cancel()
                finishWorkItem = nil
            }
        }
    }

    private func runTimeline() {
        // Reset (garante consistência se reaparecer)
        showPillars = false
        pillarsGrow = 0
        bottomRadius = 0
        textReveal = 0
        torsoFill = 0
        torsoColorIsWhite = false
        showHead = false

        // 0.00 - 0.90: preto
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            showPillars = true

            // 0.90 - 1.20: barras “sobem” (base fixa)
            withAnimation(.easeOut(duration: 0.30)) {
                pillarsGrow = 1.0
            }

            // arredondamento inferior depois que já “formou” a barra
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    // este valor será recalculado no body via GeometryReader; aqui só “liga”
                    bottomRadius = 9999
                }
            }
        }

        // 1.30 - 1.67: revela texto
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.30) {
            withAnimation(.easeOut(duration: 0.37)) {
                textReveal = 1.0
            }
        }

        // 2.67: torso começa (meia-lua cinza)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.67) {
            withAnimation(.easeOut(duration: 0.40)) {
                torsoFill = 1.0
            }
        }

        // ~2.94: cabeça (um pouco antes do seu 3.00)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.94) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                showHead = true
            }
        }

        // 3.67: torso vira branco
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.67) {
            withAnimation(.easeInOut(duration: 0.18)) {
                torsoColorIsWhite = true
            }
        }

        // 4.10: fim
        let item = DispatchWorkItem { onFinish?() }
        finishWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.10, execute: item)
    }
}

