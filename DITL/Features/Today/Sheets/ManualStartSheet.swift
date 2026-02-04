import SwiftUI

struct ManualStartSheet: View {
@AppStorage("customThemeData") private var customThemeData: Data?


    @State private var title: String = ""

    let onStart: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {

            // Header
            Text("Start Activity")
                .font(AppFonts.vt323(32))
                .foregroundColor(Color.black)

            // Activity name input
            TextField("Activity name", text: $title)
                .padding()
                .background(AppColors.lavenderQuick())
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(Color.black, lineWidth: 1)
                )

            // Start button
            Button {
                let trimmed = title.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                onStart(trimmed)
            } label: {
                Text("Start")
                    .font(AppFonts.rounded(20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(AppColors.primary())
                    .cornerRadius(AppLayout.cornerRadius)
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
