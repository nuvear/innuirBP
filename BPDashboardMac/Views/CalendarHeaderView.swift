import SwiftUI

struct CalendarHeaderView: View {
    // This will need the date range to display
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Month Row
            Text("Month").frame(height: 32)
            // Week Row
            Text("Week").frame(height: 32)
            // Day Row
            Text("Day").frame(height: 32)
            // DOW Row
            Text("DOW").frame(height: 32)
        }
    }
}
