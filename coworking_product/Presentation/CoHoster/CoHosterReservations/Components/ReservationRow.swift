import SwiftUI

struct ReservationRow: View {
    let row: ReservationRowViewData
    let greenPrimary: Color
    let grayPrimary: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Data “avatar”
            VStack {
                Text(row.dayText)
                    .font(.system(size: 20, weight: .bold))
                Text(row.monthText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 52, height: 52)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(row.guestTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    StatusChip(
                        status: row.status,
                        greenPrimary: greenPrimary,
                        grayPrimary: grayPrimary
                    )
                }
                Text(row.rangeText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}
