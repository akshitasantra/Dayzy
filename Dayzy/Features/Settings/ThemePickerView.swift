import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedCardColor: Color
    @Binding var selectedPrimaryColor: Color
    @Binding var useDarkBackground: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    struct PresetTheme: Identifiable {
        let id = UUID()
        let name: String
        let card: Color
        let primary: Color
        let darkMode: Bool
    }
    
    // MARK: - Preset Themes
    private let presetThemes: [PresetTheme] = [
        PresetTheme(name: "Blush",
                    card: Color(hex: "#FBE3EB"),
                    primary: Color(hex: "#E88AB8"),
                    darkMode: false),
        
        PresetTheme(name: "Lavender",
                    card: Color(hex: "#EEE6FF"),
                    primary: Color(hex: "#9B7EDE"),
                    darkMode: false),
        
        PresetTheme(name: "Matcha",
                    card: Color(hex: "#E7F4E4"),
                    primary: Color(hex: "#78A86F"),
                    darkMode: false),
        
        PresetTheme(name: "Ocean",
                    card: Color(hex: "#DDF3FF"),
                    primary: Color(hex: "#3A86C8"),
                    darkMode: false),
        
        PresetTheme(name: "Sunset",
                    card: Color(hex: "#FFE3D3"),
                    primary: Color(hex: "#FF8C69"),
                    darkMode: false),
        
        PresetTheme(name: "Midnight",
                    card: Color(hex: "#2B2D42"),
                    primary: Color(hex: "#8D99AE"),
                    darkMode: true),
        
        PresetTheme(name: "Cyberpunk",
                    card: Color(hex: "#2A1B3D"),
                    primary: Color(hex: "#E94584"),
                    darkMode: true),
        
        PresetTheme(name: "Forest Night",
                    card: Color(hex: "#1E2A24"),
                    primary: Color(hex: "#5FA777"),
                    darkMode: true),
        
        PresetTheme(name: "Cream Coffee",
                    card: Color(hex: "#F3E9DC"),
                    primary: Color(hex: "#9C6644"),
                    darkMode: false),
        
        PresetTheme(name: "Cherry Cola",
                    card: Color(hex: "#3B1F2B"),
                    primary: Color(hex: "#D7263D"),
                    darkMode: true)
    ]
    
    var body: some View {
        NavigationView {
            Form {
                
                // MARK: Presets
                Section("Preset Themes") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 18) {
                            ForEach(presetThemes) { theme in
                                presetCard(theme)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 12)
                    }
                }
                
                // MARK: Customization
                Section("Customize") {
                    ColorPicker("Card Color", selection: $selectedCardColor)
                    
                    ColorPicker("Primary Color", selection: $selectedPrimaryColor)
                    
                    Picker("Background", selection: $useDarkBackground) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: Reset
                Section {
                    Button("Reset Theme") {
                        selectedCardColor = Color(hex: "#FBE3EB")
                        selectedPrimaryColor = Color(hex: "#E88AB8")
                        useDarkBackground = false
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
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
    
    // MARK: - Selected State
    private func isSelected(_ theme: PresetTheme) -> Bool {
        theme.darkMode == useDarkBackground &&
        theme.card.description == selectedCardColor.description &&
        theme.primary.description == selectedPrimaryColor.description
    }
    
    // MARK: - Preset Card
    private func presetCard(_ theme: PresetTheme) -> some View {
        let selected = isSelected(theme)

        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedCardColor = theme.card
                selectedPrimaryColor = theme.primary
                useDarkBackground = theme.darkMode
            }
        } label: {
            VStack(spacing: 10) {

                ZStack {

                    // Main theme rectangle
                    RoundedRectangle(cornerRadius: 22)
                        .fill(theme.card)
                        .frame(width: 108, height: 108)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(
                                    selected
                                    ? theme.primary
                                    : Color.clear,
                                    lineWidth: 4
                                )
                        )
                        .shadow(
                            color: selected
                            ? theme.primary.opacity(0.35)
                            : .clear,
                            radius: 10
                        )

                    // Properly centered accent circle
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 40, height: 40)

                    // Floating checkmark
                    if selected {
                        VStack {
                            HStack {
                                Spacer()

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primary)
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                    )
                                    .offset(x: 6, y: -6)
                            }

                            Spacer()
                        }
                        .frame(width: 108, height: 108)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 108, height: 108)
                .scaleEffect(selected ? 1.05 : 1.0)

                Text(theme.name)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .frame(width: 108)
            }
            .padding(.vertical, 8) // increases white section card height
        }
        .buttonStyle(.plain)
    }
}
