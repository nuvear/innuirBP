import SwiftUI

struct ToolbarView: View {
    // This will need bindings to control the main view state
    
    var body: some View {
        HStack {
            Text("View:")
            Picker("View", selection: .constant("Month")) {
                Text("Week").tag("Week")
                Text("Month").tag("Month")
                Text("Year").tag("Year")
            }.pickerStyle(SegmentedPickerStyle())

            Spacer()

            Text("Smoothing:")
            Toggle("LOWESS", isOn: .constant(true))

            Spacer()

            Text("Standard:")
            Picker("Standard", selection: .constant("None")) {
                Text("None").tag("None")
                Text("ACC/AHA").tag("ACC/AHA")
                Text("ESC/ESH").tag("ESC/ESH")
                Text("JSH").tag("JSH")
                Text("ISH").tag("ISH")
            }
        }
        .padding()
    }
}
