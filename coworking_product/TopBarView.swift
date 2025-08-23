import SwiftUI

struct TopBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField("Qual região?", text: $searchText)
                    .foregroundColor(.black)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)

                Spacer()
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(12)

            Button {
                print("🔔 Notificações")
            } label: {
                Image(systemName: "bell")
                    .foregroundColor(.black)
                    .padding(10)
            }
        }
        .padding([.top, .horizontal])
        .frame(minHeight: 44)
        .animation(nil, value: searchText)
    }
}
