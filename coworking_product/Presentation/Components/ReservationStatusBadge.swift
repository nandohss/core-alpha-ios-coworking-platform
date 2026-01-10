import SwiftUI

struct ReservationStatusBadge: View {
    let status: ReservationStatusDisplayable
    
    // Optional: overrides if needed, but usually protocol drives styling
    
    var body: some View {
        HStack(spacing: 4) {
             Image(systemName: status.icon)
                .font(.caption)
             Text(status.title)
                .font(.caption.bold())
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(8)
    }
}
