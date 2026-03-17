import SwiftUI

struct DashboardView: View {
    let document: BPDataDocument

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView()
            
            // Main content
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Calendar Header
                    CalendarHeaderView()
                    
                    // Chart View
                    BPChartView(readings: document.readings)

                    // Annotation Timeline
                    AnnotationTimelineView(annotations: document.annotations)

                    // Medication Timeline
                    MedicationTimelineView(medications: document.medications)
                    DataTableView(readings: document.readings)
                }
            }
        }
        .navigationTitle("Blood Pressure Dashboard - \(document.patient.name)")
    }
}
