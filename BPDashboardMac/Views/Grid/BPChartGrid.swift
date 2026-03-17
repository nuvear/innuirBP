import SwiftUI

struct BPChartGrid: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Canvas {
            context, size in
            
            let yRange = viewModel.valueRange
            let dayCount = viewModel.allDays.count
            
            // Function to map (dayIndex, value) to canvas coordinates
            func point(for dayIndex: Int, value: Double) -> CGPoint {
                let x = (Double(dayIndex) + 0.5) * GridConstants.colWidth
                let y = size.height - (value - yRange.lowerBound) / (yRange.upperBound - yRange.lowerBound) * size.height
                return CGPoint(x: x, y: y)
            }
            
            // 1. Draw Goal Bands
            for band in viewModel.goalBands {
                let yStart = point(for: 0, value: band.sysMax).y
                let yEnd = point(for: 0, value: band.sysMin).y
                let rect = CGRect(x: 0, y: yStart, width: size.width, height: yEnd - yStart)
                context.fill(Path(rect), with: .color(band.color))
            }
            
            // 2. Draw LOWESS Trend Lines
            if viewModel.showSmoothing {
                var sysPath = Path()
                var diaPath = Path()
                for (i, day) in viewModel.allDays.enumerated() {
                    if !viewModel.smoothedSystolic[i].isNaN {
                        let pt = point(for: i, value: viewModel.smoothedSystolic[i])
                        if sysPath.isEmpty { sysPath.move(to: pt) } else { sysPath.addLine(to: pt) }
                    }
                    if !viewModel.smoothedDiastolic[i].isNaN {
                        let pt = point(for: i, value: viewModel.smoothedDiastolic[i])
                        if diaPath.isEmpty { diaPath.move(to: pt) } else { diaPath.addLine(to: pt) }
                    }
                }
                context.stroke(sysPath, with: .color(.cyan), lineWidth: 2.5)
                context.stroke(diaPath, with: .color(.brown), lineWidth: 2.5)
            }
            
            // 3. Draw Individual Reading Dots
            for (i, day) in viewModel.allDays.enumerated() {
                if let readings = viewModel.readingsByDay[day] {
                    for reading in readings {
                        // Systolic
                        let sysPt = point(for: i, value: Double(reading.systolic))
                        context.fill(Path(ellipseIn: CGRect(center: sysPt, size: CGSize(width: 7, height: 7))), with: .color(.cyan.opacity(0.6)))
                        
                        // Diastolic
                        let diaPt = point(for: i, value: Double(reading.diastolic))
                        context.fill(Path(ellipseIn: CGRect(center: diaPt, size: CGSize(width: 6, height: 6))), with: .color(.brown.opacity(0.6)))
                        
                        // Pulse
                        let pulsePt = point(for: i, value: Double(reading.pulse))
                        context.fill(Path(ellipseIn: CGRect(center: pulsePt, size: CGSize(width: 4, height: 4))), with: .color(.purple.opacity(0.5)))
                    }
                }
            }
        }
        .frame(height: GridConstants.chartRowHeight)
    }
}

extension CGRect {
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }
}
