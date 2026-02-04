import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedCardColor: Color
    @Binding var selectedPrimaryColor: Color
    @Binding var useDarkBackground: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                ColorPicker("Card Color", selection: $selectedCardColor)
                ColorPicker("Primary Color", selection: $selectedPrimaryColor)

                Picker("Background", selection: $useDarkBackground) {
                    Text("Light").tag(false)
                    Text("Dark").tag(true)
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Choose Your Theme")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
