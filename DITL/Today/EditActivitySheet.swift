import SwiftUI

struct EditActivitySheet: View {
    enum Mode{
        case add, edit
    }
    
    let activity: Activity
    let mode: Mode

    @State private var title: String
    @State private var startTime: Date
    @State private var endTime: Date

    let onSave: (String, Date, Date) -> Void

    @Environment(\.dismiss) private var dismiss

    init(activity: Activity, mode: Mode = .edit, onSave: @escaping (String, Date, Date) -> Void) {
        self.activity = activity
        self.mode = mode
        self.onSave = onSave
        _title = State(initialValue: activity.title)
        _startTime = State(initialValue: activity.startTime)
        _endTime = State(initialValue: activity.endTime ?? Date())
    }

    var body: some View {
        VStack(spacing: 24) {

            Text(mode == .add ? "Add Activity" : "Edit Activity")
                .font(AppFonts.vt323(32))
                .foregroundColor(AppColors.black)

            // Title field
            TextField("Activity name", text: $title)
                .padding()
                .background(AppColors.lavenderQuick)
                .cornerRadius(AppLayout.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                        .stroke(Color.black, lineWidth: 1)
                )

            // Start time
            DatePicker(
                "Start Time",
                selection: $startTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(AppFonts.rounded(16))

            // End time
            DatePicker(
                "End Time",
                selection: $endTime,
                displayedComponents: [.date, .hourAndMinute]
            )
            .font(AppFonts.rounded(16))

            Button {
                guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                guard endTime >= startTime else { return }

                onSave(title, startTime, endTime)
                dismiss()
            } label: {
                Text("Save")
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
