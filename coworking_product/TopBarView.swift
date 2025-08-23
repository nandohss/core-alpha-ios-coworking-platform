import SwiftUI

struct TopBarView: View {
    var body: some View {
        HStack {
            Text("Coworking")
                .font(.title2)
                .bold()
            Spacer()
        }
        .padding()
        .background(Color.white)
    }
}
