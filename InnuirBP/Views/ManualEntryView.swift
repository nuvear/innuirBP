// ManualEntryView.swift
// InnuirBP
//
// The manual blood pressure entry modal sheet.
// Matches the Apple Health iPad reference screenshot (4.jpg):
// - BP icon at top
// - "Blood Pressure" title (bold)
// - Date field (tappable, defaults to today, allows past dates)
// - Systolic field with placeholder "e.g. 115"
// - Diastolic field with placeholder "e.g. 75"
// - Instructional footnote
// - Numeric keypad
// - X (cancel) and checkmark (save) buttons in toolbar

import SwiftUI
import SwiftData

struct ManualEntryView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var selectedDate: Date = Date()
    @State private var systolicText: String = ""
    @State private var diastolicText: String = ""
    @State private var activeField: ActiveField? = .systolic
    @State private var showDatePicker: Bool = false
    @State private var showValidationError: Bool = false

    enum ActiveField {
        case systolic, diastolic
    }

    // MARK: - Validation

    private var systolicValue: Double? { Double(systolicText) }
    private var diastolicValue: Double? { Double(diastolicText) }

    private var isValid: Bool {
        guard let sys = systolicValue, let dia = diastolicValue else { return false }
        return sys >= 60 && sys <= 250 && dia >= 40 && dia <= 150 && sys > dia
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // ── Icon + Title ───────────────────────────────────────────
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 64, height: 64)
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color(.systemRed))
                    }
                    Text("Blood Pressure")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(.label))
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                // ── Form Fields ────────────────────────────────────────────
                VStack(spacing: 0) {
                    // Date row
                    HStack {
                        Text("Date")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Button {
                            showDatePicker.toggle()
                        } label: {
                            Text(formattedDate)
                                .font(.system(size: 17))
                                .foregroundStyle(Color(.systemBlue))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color(.systemBackground))

                    if showDatePicker {
                        DatePicker(
                            "Select Date",
                            selection: $selectedDate,
                            in: ...Date(),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.graphical)
                        .padding(.horizontal, 20)
                        .background(Color(.systemBackground))
                    }

                    Divider().padding(.leading, 20)

                    // Systolic row
                    HStack {
                        Text("Systolic")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text(systolicText.isEmpty ? "e.g. 115" : systolicText)
                            .font(.system(size: 17))
                            .foregroundStyle(systolicText.isEmpty ? Color(.placeholderText) : Color(.label))
                            .onTapGesture { activeField = .systolic }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        activeField == .systolic
                            ? Color(.systemBlue).opacity(0.05)
                            : Color(.systemBackground)
                    )

                    Divider().padding(.leading, 20)

                    // Diastolic row
                    HStack {
                        Text("Diastolic")
                            .font(.system(size: 17))
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text(diastolicText.isEmpty ? "e.g. 75" : diastolicText)
                            .font(.system(size: 17))
                            .foregroundStyle(diastolicText.isEmpty ? Color(.placeholderText) : Color(.label))
                            .onTapGesture { activeField = .diastolic }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        activeField == .diastolic
                            ? Color(.systemBlue).opacity(0.05)
                            : Color(.systemBackground)
                    )

                    Divider()
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 20)

                // ── Footnote ───────────────────────────────────────────────
                HStack {
                    Text("Try to position the blood pressure cuff in the same location each time. ")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                    + Text("Learn More...")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.systemBlue))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                Spacer()

                // ── Custom Numeric Keypad ──────────────────────────────────
                BPNumericKeypad { key in
                    handleKeyInput(key)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)

                // ── Validation Error ───────────────────────────────────────
                if showValidationError {
                    Text("Please enter valid systolic and diastolic values.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.systemRed))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveReading()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isValid ? Color(.systemBlue) : Color(.systemGray3))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(.systemGray5)))
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: selectedDate)
    }

    private func handleKeyInput(_ key: NumpadKey) {
        switch key {
        case .digit(let d):
            let str = String(d)
            if activeField == .systolic {
                if systolicText.count < 3 { systolicText += str }
            } else {
                if diastolicText.count < 3 { diastolicText += str }
            }
        case .delete:
            if activeField == .systolic {
                if !systolicText.isEmpty { systolicText.removeLast() }
            } else {
                if !diastolicText.isEmpty { diastolicText.removeLast() }
            }
        }
    }

    private func saveReading() {
        guard let sys = systolicValue, let dia = diastolicValue, isValid else {
            showValidationError = true
            return
        }

        let reading = BPReading(
            systolic: sys,
            diastolic: dia,
            timestamp: selectedDate,
            source: .manual
        )
        modelContext.insert(reading)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Numeric Keypad

enum NumpadKey {
    case digit(Int)
    case delete
}

struct BPNumericKeypad: View {
    let onKey: (NumpadKey) -> Void

    private let layout: [[NumpadKey?]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [nil,       .digit(0), .delete  ]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(0..<layout.count, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(0..<layout[row].count, id: \.self) { col in
                        if let key = layout[row][col] {
                            Button {
                                onKey(key)
                            } label: {
                                keyLabel(key)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(.systemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyLabel(_ key: NumpadKey) -> some View {
        switch key {
        case .digit(let d):
            Text("\(d)")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(Color(.label))
        case .delete:
            Image(systemName: "delete.left")
                .font(.system(size: 20))
                .foregroundStyle(Color(.label))
        }
    }
}
