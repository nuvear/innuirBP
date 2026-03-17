import SwiftUI

struct YAxisView: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Canvas { context, size in
            let yRange = viewModel.valueRange
            let tickValues = stride(from: floor(yRange.lowerBound / 20) * 20, to: yRange.upperBound, by: 20).map { $0 }
            
            for tick in tickValues {
                let y = size.height - (tick - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound) * size.height
                let text = Text("\(Int(tick))").font(.caption).foregroundColor(.secondary)
                context.draw(text, at: CGPoint(x: size.width - 8, y: y), anchor: .trailing)
            }
        }
    }
}
