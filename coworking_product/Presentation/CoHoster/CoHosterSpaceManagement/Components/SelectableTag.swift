import SwiftUI

struct SelectableTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(isSelected ? Color.black : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .black)
        }
        .buttonStyle(.plain)
    }
}
