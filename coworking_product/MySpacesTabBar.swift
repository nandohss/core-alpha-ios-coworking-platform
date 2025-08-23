import SwiftUI

struct MySpacesTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "square.grid.2x2", label: "Espaços", index: 0)
            Spacer()
            tabBarItem(icon: "calendar", label: "Reservas", index: 1)
        }
        .padding(.horizontal, 32)
        .padding(.top, 10)
        .padding(.bottom, safeBottomPadding + 10)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .top)
    }

    private var safeBottomPadding: CGFloat {
        // Tenta pegar a keyWindow de forma segura; fallback 16 para Preview
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        let keyWindow = windowScene?.windows.first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.bottom ?? 16
    }

    @ViewBuilder
    private func tabBarItem(icon: String, label: String, index: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: selectedTab == index ? 22 : 20, weight: .medium))
                    .scaleEffect(selectedTab == index ? 1.15 : 1.0)
                    .opacity(selectedTab == index ? 1.0 : 0.7)
                    .foregroundColor(selectedTab == index ? .black : .gray)
                    .animation(.easeInOut(duration: 0.2), value: selectedTab)

                Text(label)
                    .font(.caption)
                    .foregroundColor(selectedTab == index ? .black : .gray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
