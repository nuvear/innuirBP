import SwiftUI

struct AnnotationTimelineView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedAnnotation: Annotation?
    @State private var showPopover = false

    private let colWidth: CGFloat = 32
    private let rowHeight: CGFloat = 32

    private let tagEmoji: [String: String] = [
        "lifestyle": "🌅",
        "exercise":  "🚶",
        "diet":      "🥗",
        "medication":"💊",
        "stress":    "⚡"
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.allDays, id: \.self) { day in
                ZStack {
                    if let ann = annotation(for: day) {
                        Button {
                            selectedAnnotation = ann
                            showPopover = true
                        } label: {
                            Text(tagEmoji[ann.tag] ?? "📌")
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: Binding(
                            get: { showPopover && selectedAnnotation?.id == ann.id },
                            set: { if !$0 { showPopover = false } }
                        )) {
                            AnnotationPopover(annotation: ann)
                        }
                    }
                }
                .frame(width: colWidth, height: rowHeight)
            }
        }
    }

    private func annotation(for day: Date) -> Annotation? {
        viewModel.document.annotations.first {
            Calendar.current.isDate($0.timestamp, inSameDayAs: day)
        }
    }
}

struct AnnotationPopover: View {
    let annotation: Annotation

    private let tagColor: [String: Color] = [
        "lifestyle": .orange,
        "exercise":  .green,
        "diet":      .teal,
        "medication":".blue",
        "stress":    .red
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(annotation.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(annotation.tag.uppercased())
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(tagColor[annotation.tag] ?? .gray)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Text(annotation.title)
                .font(.headline)
            Text(annotation.text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text("— \(annotation.author)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: 320)
    }
}
