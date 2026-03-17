import SwiftUI

struct DataTableView: View {
    let readings: [BPReading]
    // This will need the date range and layout logic

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("SYS").frame(width: 80)
                ForEach(readings) { reading in
                    Text("\(reading.systolic)")
                        .frame(width: 32)
                }
            }
            HStack(spacing: 0) {
                Text("DIA").frame(width: 80)
                ForEach(readings) { reading in
                    Text("\(reading.diastolic)")
                        .frame(width: 32)
                }
            }
            HStack(spacing: 0) {
                Text("PULSE").frame(width: 80)
                ForEach(readings) { reading in
                    Text("\(reading.pulse)")
                        .frame(width: 32)
                }
            }
        }
    }
}
