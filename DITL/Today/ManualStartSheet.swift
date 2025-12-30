import SwiftUI

struct ManualStartSheet: View {
    @State private var title: String = ""
    let onStart: (String) -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Start Activity")
                .font(AppFonts.vt323(32))
                .foregroundColor(AppColors.black)

            TextField("Activity name", text: $title)
                .padding()
                .background(AppColors.lavenderQuick)
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(Color.black, lineWidth: 1)
                )

            Button {
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                onStart(title)
            } label: {
                Text("Start")
                    .font(AppFonts.rounded(20))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(AppColors.pinkPrimary)
                    .cornerRadius(AppLayout.cornerRadius)
            }

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
