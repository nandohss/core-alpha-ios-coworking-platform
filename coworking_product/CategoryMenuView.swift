import SwiftUI

struct CategoryMenuView: View {
    @Binding var selected: FormsConstants.CategoriaPrincipal
    let categories: [FormsConstants.CategoriaPrincipal]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(categories) { category in
                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(selected == category ? .black : .gray)

                        Text(category.rawValue)
                            .font(.footnote)
                            .foregroundColor(selected == category ? .black : .gray)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selected == category ? Color.white : Color.clear)
                    )
                    .onTapGesture {
                        selected = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}
