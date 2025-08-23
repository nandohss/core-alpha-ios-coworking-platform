import SwiftUI
import Amplify


struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        ZStack {
            Color.white.opacity(0.6)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))

                Text(message)
                    .foregroundColor(.gray)
                    .font(.headline)
            }
            .padding(24)
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}
