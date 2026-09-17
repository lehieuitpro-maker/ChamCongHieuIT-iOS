import SwiftData
import SwiftUI

@MainActor
struct AttendanceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkEntry.date, order: .forward) private var allEntries: [WorkEntry]

    @AppStorage(AppStorageKey.startHour) private var startHour = 8
    @AppStorage(AppStorageKey.startMinute) private var startMinute = 0
    @AppStorage(AppStorageKey.endHour) private var endHour = 17
    @AppStorage(AppStorageKey.endMinute) private var endMinute = 0
    @AppStorage(AppStorageKey.breakMinutes) private var breakMinutes = 60
    @AppStorage(AppStorageKey.standardMinutes) private var standardMinutes = 480
    @AppStorage(AppStorageKey.worksMonday) private var worksMonday = true
    @AppStorage(AppStorageKey.worksTuesday) private var worksTuesday = true
    @AppStorage(AppStorageKey.worksWednesday) private var worksWednesday = true
    @AppStorage(AppStorageKey.worksThursday) private var worksThursday = true
    @AppStorage(AppStorageKey.worksFriday) private var worksFriday = true
    @AppStorage(AppStorageKey.worksSaturday) private var worksSaturday = false
    @AppStorage(AppStorageKey.worksSunday) private var worksSunday = false
    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true

    @State private var selectedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var presentedSheet: AttendanceSheet?
    @State private var alertDestination: AttendanceAlert?

    private let calendar = Calendar.current

    var body: some View {
        List {
            Section {
                MonthSwitcher(selectedMonth: $selectedMonth)
            }
            .listRowInsets(.init(top: 12, leading: 16, bottom: 4, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                AttendanceSummaryCard(
                    workedDays: workedDays,
                    totalMinutes: totalMinutes,
                    overtimeMinutes: overtimeMinutes
                )
            } header: {
                AppSectionHeader(title: "Tổng quan", systemImage: "chart.bar.fill")
            }
            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                VStack(spacing: 10) {
                    Button {
                        generateMonth()
                    } label: {
                        Label("Tạo công theo lịch cố định", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Button(role: .destructive) {
                        alertDestination = .confirmMonthDeletion(selectedMonth)
                    } label: {
                        Label("Xóa dữ liệu tháng này", systemImage: "trash")
                    }
                    .buttonStyle(TintedActionButtonStyle(tint: .red))
                    .disabled(monthEntries.isEmpty)
                    .opacity(monthEntries.isEmpty ? 0.45 : 1)
                }
                .appCard()
            } footer: {
                Text("Tạo lịch chỉ thêm ngày còn thiếu. Xóa tháng sẽ xóa toàn bộ ngày công của tháng đang chọn.")
            }
            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                if monthEntries.isEmpty {
                    ContentUnavailableView(
                        "Chưa có dữ liệu",
                        systemImage: "calendar",
                        description: Text("Tạo công theo lịch cố định hoặc thêm từng ngày bằng nút +.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .appCard()
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(monthEntries) { entry in
                        Button {
                            presentedSheet = .edit(entry)
                        } label: {
                            AttendanceRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(.init(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions {
                            Button("Xóa", role: .destructive) {
                                deleteEntry(entry)
                            }
                        }
                    }
                }
            } header: {
                AppSectionHeader(
                    title: monthEntries.isEmpty ? "Chi tiết" : "\(monthEntries.count) ngày trong tháng",
                    systemImage: "list.bullet.rectangle"
                )
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(14)
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Chấm công")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentedSheet = .new(.now)
                } label: {
                    Label("Thêm ngày", systemImage: "plus")
                }
            }
        }
        .sheet(item: $presentedSheet) { sheet in
            Group {
                switch sheet {
                case .new(let date):
                    EntryEditorView(
                        entry: nil,
                        defaultDate: date,
                        schedule: schedule
                    )
                case .edit(let entry):
                    EntryEditorView(
                        entry: entry,
                        defaultDate: entry.date,
                        schedule: schedule
                    )
                }
            }
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
        }
        .alert(item: $alertDestination) { destination in
            switch destination {
            case .information(let message):
                Alert(
                    title: Text("Thông báo"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            case .confirmMonthDeletion(let month):
                Alert(
                    title: Text("Xóa dữ liệu \(month.vietnameseMonthYear)?"),
                    message: Text("Toàn bộ ngày công trong tháng này sẽ bị xóa. Bạn có thể tạo lại ngay sau đó."),
                    primaryButton: .destructive(Text("Xóa tháng")) {
                        deleteMonth(month)
                    },
                    secondaryButton: .cancel(Text("Hủy"))
                )
            }
        }
    }

    private var monthEntries: [WorkEntry] {
        allEntries.filter { calendar.isDate($0.date, inSameMonthAs: selectedMonth) }
    }

    private var workedDays: Int {
        monthEntries.filter { $0.status == .work && $0.totalMinutes > 0 }.count
    }

    private var totalMinutes: Int {
        monthEntries.reduce(0) { $0 + $1.totalMinutes }
    }

    private var overtimeMinutes: Int {
        monthEntries.reduce(0) { result, entry in
            result + max(0, entry.totalMinutes - standardMinutes)
        }
    }

    private var schedule: ScheduleDefaults {
        ScheduleDefaults(
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            breakMinutes: breakMinutes,
            standardMinutes: standardMinutes,
            workingWeekdays: workingWeekdays
        )
    }

    private var workingWeekdays: Set<Int> {
        var weekdays = Set<Int>()
        if worksSunday { weekdays.insert(1) }
        if worksMonday { weekdays.insert(2) }
        if worksTuesday { weekdays.insert(3) }
        if worksWednesday { weekdays.insert(4) }
        if worksThursday { weekdays.insert(5) }
        if worksFriday { weekdays.insert(6) }
        if worksSaturday { weekdays.insert(7) }
        return weekdays
    }

    private func generateMonth() {
        let existingDates = Set(allEntries.map { calendar.startOfDay(for: $0.date) })
        let dates = calendar.datesInMonth(containing: selectedMonth)
        var createdCount = 0

        for date in dates {
            let weekday = calendar.component(.weekday, from: date)
            guard schedule.workingWeekdays.contains(weekday) else { continue }

            let normalizedDate = calendar.startOfDay(for: date)
            guard !existingDates.contains(normalizedDate) else { continue }

            let entry = WorkEntry(
                date: normalizedDate,
                startTime: schedule.startTime(on: normalizedDate),
                endTime: schedule.endTime(on: normalizedDate),
                breakMinutes: schedule.breakMinutes
            )
            modelContext.insert(entry)
            createdCount += 1
        }

        do {
            try modelContext.save()
            HapticFeedback.success(isEnabled: hapticsEnabled)
            alertDestination = .information(
                createdCount == 0
                    ? "Tháng này đã có đủ dữ liệu theo lịch đã đặt."
                    : "Đã thêm \(createdCount) ngày làm việc."
            )
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            alertDestination = .information(
                "Không thể lưu dữ liệu: \(error.localizedDescription)"
            )
        }
    }

    private func deleteMonth(_ month: Date) {
        let entriesToDelete = allEntries.filter {
            calendar.isDate($0.date, inSameMonthAs: month)
        }

        for entry in entriesToDelete {
            modelContext.delete(entry)
        }

        do {
            try modelContext.save()
            HapticFeedback.warning(isEnabled: hapticsEnabled)
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            alertDestination = .information(
                "Không thể xóa dữ liệu: \(error.localizedDescription)"
            )
        }
    }

    private func deleteEntry(_ entry: WorkEntry) {
        modelContext.delete(entry)
        do {
            try modelContext.save()
            HapticFeedback.warning(isEnabled: hapticsEnabled)
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            alertDestination = .information(
                "Không thể xóa ngày công: \(error.localizedDescription)"
            )
        }
    }
}

private enum AttendanceSheet: Identifiable {
    case new(Date)
    case edit(WorkEntry)

    var id: String {
        switch self {
        case .new:
            "new-entry"
        case .edit(let entry):
            "edit-\(entry.id.uuidString)"
        }
    }
}

private enum AttendanceAlert: Identifiable {
    case information(String)
    case confirmMonthDeletion(Date)

    var id: String {
        switch self {
        case .information(let message):
            "information-\(message)"
        case .confirmMonthDeletion(let month):
            "delete-\(month.timeIntervalSinceReferenceDate)"
        }
    }
}

struct MonthSwitcher: View {
    @Binding var selectedMonth: Date
    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 14) {
            Button {
                selectedMonth = calendar.addingMonths(-1, to: selectedMonth)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.indigo)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.indigo.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tháng trước")

            Spacer()

            VStack(spacing: 3) {
                Text("BẢNG CÔNG")
                    .font(.caption2.weight(.bold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Text(selectedMonth.vietnameseMonthYear)
                    .font(.headline)
            }

            Spacer()

            Button {
                selectedMonth = calendar.addingMonths(1, to: selectedMonth)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppTheme.indigo)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.indigo.opacity(0.1), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Tháng sau")
        }
        .appCard(padding: 12)
    }
}

private struct AttendanceSummaryCard: View {
    let workedDays: Int
    let totalMinutes: Int
    let overtimeMinutes: Int

    var body: some View {
        HStack(spacing: 12) {
            MetricItem(
                title: "Ngày công",
                value: "\(workedDays)",
                systemImage: "calendar.badge.checkmark"
            )

            Divider()
                .overlay(.white.opacity(0.24))

            MetricItem(
                title: "Tổng giờ",
                value: totalMinutes.attendanceCompactDuration,
                systemImage: "clock.fill"
            )

            Divider()
                .overlay(.white.opacity(0.24))

            MetricItem(
                title: "Tăng ca",
                value: overtimeMinutes.attendanceCompactDuration,
                systemImage: "bolt.fill"
            )
        }
        .padding(18)
        .background(AppTheme.brandGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: AppTheme.indigo.opacity(0.2), radius: 14, y: 8)
    }
}

private struct AttendanceRow: View {
    let entry: WorkEntry

    var body: some View {
        HStack(spacing: 13) {
            VStack(spacing: 3) {
                Text(entry.date.vietnameseDayNumber)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.indigo)
                Text(entry.date.vietnameseWeekday)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 58, height: 58)
            .background(AppTheme.softBrandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.status.tintColor)
                        .frame(width: 7, height: 7)
                    Text(entry.status.title)
                        .font(.subheadline.weight(.semibold))
                }

                if entry.status == .work {
                    Text(
                        "\(entry.startTime.vietnameseShortTime) – \(entry.endTime.vietnameseShortTime)"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.totalMinutes.attendanceDurationText)
                    .font(.subheadline.weight(.semibold))

                if entry.isManuallyEdited {
                    Label("Đã sửa", systemImage: "pencil")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .contentShape(Rectangle())
        .appCard(padding: 12)
    }
}

#Preview {
    NavigationStack {
        AttendanceView()
    }
    .modelContainer(for: WorkEntry.self, inMemory: true)
}
