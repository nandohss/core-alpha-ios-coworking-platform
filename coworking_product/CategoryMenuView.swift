import SwiftUI

struct CategoryMenuView: View {
    @Binding var selected: String
    let categories: [HomeView.Category]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories) { category in
                    Button {
                        selected = category.name
                    } label: {
                        VStack {
                            Image(systemName: category.icon)
                            Text(category.name)
                                .font(.caption)
                        }
                        .padding(8)
                        .background(selected == category.name ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}
