import SwiftUI
import UIKit

public extension View {
    /// Dismiss the keyboard when tapping anywhere in this view's bounds.
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}
