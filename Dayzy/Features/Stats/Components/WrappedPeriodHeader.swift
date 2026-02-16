import SwiftUI

struct WrappedPeriodHeader: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let disableNext: Bool   // New flag

    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(AppColors.primary())
            }

            Spacer()

            Text(title)
                .font(AppFonts.vt323(28))
                .foregroundColor(AppColors.primary())

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(disableNext ? Color.gray : AppColors.primary())
            }
            .disabled(disableNext) // Disable if future period
        }
        .padding(.horizontal)
    }
}
