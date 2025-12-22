import SwiftUI

struct TimelineSection: View {

    let entries = [
        ("8:12 AM – 9:47 AM", "Homework"),
        ("9:47 AM – 10:30 AM", "Doomscrolling"),
        ("11:00 AM – 12:15 PM", "Class"),
        ("1:00 PM – 2:30 PM", "Studying"),
        ("3:00 PM – 4:00 PM", "Gym")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Header
            Text("Today’s Timeline")
                .font(AppFonts.vt323(40))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Caption
            Text("Add a clip & track your time here")
                .font(AppFonts.rounded(12))
                .foregroundColor(AppColors.black)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            // Timeline Card
            VStack {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(entries, id: \.0) { entry in
                            TimelineEntryRow(
                                timeRange: entry.0,
                                activity: entry.1
                            )
                        }
                    }
                    .padding(16)
                }
            }
            .frame(height: 140) // controls visible scroll area
            .background(AppColors.pinkCard)
            .cornerRadius(AppLayout.cornerRadius)
            // Black outline
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            // Drop shadow
            .shadow(
                color: Color.black.opacity(0.10),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .padding(.horizontal, AppLayout.screenPadding)
        .padding(.top, 32)
    }
}

#Preview {
    ZStack {
        AppColors.background
        TimelineSection()
    }
}
