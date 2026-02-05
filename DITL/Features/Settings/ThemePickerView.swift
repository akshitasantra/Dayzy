import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedCardColor: Color
    @Binding var selectedPrimaryColor: Color
    @Binding var useDarkBackground: Bool

    @Environment(\.dismiss) private var dismiss

    // Default colors
    private let defaultCardColor = Color(hex: "#FBE3EB")
    private let defaultPrimaryColor = Color(hex: "#E88AB8")

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ColorPicker("Card Color", selection: $selectedCardColor)
                    ColorPicker("Primary Color", selection: $selectedPrimaryColor)
                    
                    Button("Reset Theme") {
                        let defaultCard = Color(hex: "#FBE3EB")
                        let defaultPrimary = Color(hex: "#E88AB8")
                        selectedCardColor = defaultCard
                        selectedPrimaryColor = defaultPrimary
                        useDarkBackground = false
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section {
                    Picker("Background", selection: $useDarkBackground) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
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
