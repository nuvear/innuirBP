import SwiftUI

struct AnnotationGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedAnnotation: Annotation?

    private let tagEmoji: [String: String] = [
        "lifestyle": "🌅", "exercise":  "🚶", "diet": "🥗", "medication":"💊", "stress": "⚡"
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.allDays, id: \.self) { day in
                ZStack {
                    if let ann = annotation(for: day) {
                        Button {
                            selectedAnnotation = ann
                        } label: {
                            Text(tagEmoji[ann.tag] ?? "📌").font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .popover(item: $selectedAnnotation) { annotation in
                            AnnotationPopover(annotation: annotation)
                        }
                    }
                }
                .frame(width: GridConstants.colWidth, height: GridConstants.notesRowHeight)
            }
        }
    }

    private func annotation(for day: Date) -> Annotation? {
        viewModel.document.annotations.first { Calendar.current.isDate($0.timestamp, inSameDayAs: day) }
    }
}

extension Annotation: Identifiable {}
