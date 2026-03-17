import SwiftUI

struct AnnotationTimelineView: View {
    let annotations: [Annotation]
    // This will need the date range and positioning logic

    var body: some View {
        HStack {
            ForEach(annotations) { annotation in
                VStack {
                    Text(annotation.tag)
                    Text(annotation.date)
                }
                .padding()
            }
        }
    }
}
