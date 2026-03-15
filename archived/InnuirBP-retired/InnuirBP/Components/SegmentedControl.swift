// SegmentedControl.swift
// InnuirBP
//
// A custom segmented control that exactly matches the Apple Health
// UISegmentedControl appearance: gray container, white active pill,
// layered shadow on the active segment.

import SwiftUI

struct BPSegmentedControl<T: Hashable & CustomStringConvertible>: View {

    let options: [T]
    @Binding var selected: T

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected = option
                    }
                } label: {
                    Text(option.description)
                        .font(.system(size: 13, weight: selected == option ? .semibold : .regular))
                        .foregroundStyle(Color(.label))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(
                            Group {
                                if selected == option {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                                        .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(.systemGray5))
        )
    }
}

// MARK: - BPTimeRange + CustomStringConvertible

extension BPTimeRange: CustomStringConvertible {
    var description: String { rawValue }
}

// MARK: - GuidelineType + CustomStringConvertible

extension GuidelineType: CustomStringConvertible {
    var description: String { displayName }
}
