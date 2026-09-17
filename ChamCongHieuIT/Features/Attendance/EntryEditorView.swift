import SwiftData
import SwiftUI

@MainActor
struct EntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let entry: WorkEntry?
    let schedule: ScheduleDefaults

    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true
    @State private var date: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var breakMinutes: Int
    @State private var status: WorkStatus
    @State private var note: String
    @State private var saveFailure: SaveFailure?

    private let calendar = Calendar.current

    init(
        entry: WorkEntry?,
        defaultDate: Date,
        schedule: ScheduleDefaults
    ) {
        self.entry = entry
        self.schedule = schedule

        let initialDate = entry?.date ?? defaultDate
        _date = State(initialValue: initialDate)
        _startTime = State(initialValue: entry?.startTime ?? schedule.startTime(on: initialDate))
        _endTime = State(initialValue: entry?.endTime ?? schedule.endTime(on: initialDate))
        _breakMinutes = State(initialValue: entry?.breakMinutes ?? schedule.breakMinutes)
        _status = State(initialValue: entry?.status ?? .work)
        _note = State(initialValue: entry?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EditorSummaryCard(
                        date: date,
                        status: status,
                        totalMinutes: calculatedMinutes
                    )
                }
                .listRowInsets(.init(top: 12, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)

                Section {
                    DatePicker(
                        selection: $date,
                        displayedComponents: .date
                    ) {
                        Label("Ngày", systemImage: "calendar")
                    }

                    Picker(selection: $status) {
                        ForEach(WorkStatus.allCases) { item in
                            Label(item.title, systemImage: item.systemImage)
                                .tag(item)
                        }
                    } label: {
                        Label("Trạng thái", systemImage: "checkmark.circle")
                    }
                } header: {
                    AppSectionHeader(title: "Ngày làm việc", systemImage: "calendar.badge.clock")
                }

                if status == .work {
                    Section {
                        DatePicker(
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            Label("Giờ bắt đầu", systemImage: "play.circle.fill")
                        }
                        DatePicker(
                            selection: $endTime,
                            displayedComponents: .hourAndMinute
                        ) {
                            Label("Giờ kết thúc", systemImage: "stop.circle.fill")
                        }
                        Stepper(value: $breakMinutes, in: 0...240, step: 5) {
                            Label("Thời gian nghỉ: \(breakMinutes) phút", systemImage: "pause.circle.fill")
                        }

                        LabeledContent(
                            content: {
                                Text(calculatedMinutes.attendanceDurationText)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.indigo)
                            },
                            label: {
                                Label("Giờ công", systemImage: "clock.fill")
                            }
                        )
                    } header: {
                        AppSectionHeader(title: "Thời gian", systemImage: "clock.fill")
                    }
                }

                Section {
                    TextField("Ví dụ: tăng ca, đi muộn…", text: $note, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    AppSectionHeader(title: "Ghi chú", systemImage: "note.text")
                }

                if !isValid {
                    Section {
                        Label(
                            "Giờ kết thúc phải sau giờ bắt đầu và thời gian nghỉ.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .tint(AppTheme.indigo)
            .navigationTitle(entry == nil ? "Thêm ngày công" : "Sửa ngày công")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .alert(item: $saveFailure) { failure in
                Alert(
                    title: Text("Không thể lưu"),
                    message: Text(failure.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private var calculatedMinutes: Int {
        guard status == .work else { return 0 }
        let start = minutesSinceMidnight(startTime)
        let end = minutesSinceMidnight(endTime)
        return max(0, end - start - breakMinutes)
    }

    private var isValid: Bool {
        status != .work || calculatedMinutes > 0
    }

    private func minutesSinceMidnight(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    private func save() {
        let normalizedDate = calendar.startOfDay(for: date)
        let combinedStart = calendar.combining(day: normalizedDate, time: startTime)
        let combinedEnd = calendar.combining(day: normalizedDate, time: endTime)

        if let entry {
            entry.date = normalizedDate
            entry.startTime = combinedStart
            entry.endTime = combinedEnd
            entry.breakMinutes = breakMinutes
            entry.status = status
            entry.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.isManuallyEdited = true
            entry.updatedAt = .now
        } else {
            let newEntry = WorkEntry(
                date: normalizedDate,
                startTime: combinedStart,
                endTime: combinedEnd,
                breakMinutes: breakMinutes,
                status: status,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                isManuallyEdited: true
            )
            modelContext.insert(newEntry)
        }

        do {
            try modelContext.save()
            HapticFeedback.success(isEnabled: hapticsEnabled)
            dismiss()
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            saveFailure = SaveFailure(message: error.localizedDescription)
        }
    }
}

private struct EditorSummaryCard: View {
    let date: Date
    let status: WorkStatus
    let totalMinutes: Int

    var body: some View {
        HStack(spacing: 14) {
            IconTile(systemImage: status.systemImage, tint: status.tintColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(date.vietnameseFullDate)
                    .font(.subheadline.weight(.semibold))
                Text(status.title)
                    .font(.caption)
                    .foregroundStyle(status.tintColor)
            }

            Spacer()

            if status == .work {
                Text(totalMinutes.attendanceCompactDuration)
                    .font(.headline)
                    .foregroundStyle(AppTheme.indigo)
            }
        }
        .appCard()
    }
}

private struct SaveFailure: Identifiable {
    let id = UUID()
    let message: String
}
