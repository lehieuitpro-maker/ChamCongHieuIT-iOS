import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var backupDocument: BackupExportDocument?
    @State private var pendingBackup: AttendanceBackup?
    @State private var isImporting = false
    @State private var isConfirmingRestore = false
    @State private var backupMessage: BackupMessage?
    @AppStorage(AppStorageKey.employeeName) private var employeeName = ""
    @AppStorage(AppStorageKey.companyName) private var companyName = ""
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
    @AppStorage(AppStorageKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue

    private let calendar = Calendar.current

    var body: some View {
        Form {
            Section {
                SettingsHeroCard()
            }
            .listRowInsets(.init(top: 12, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)

            Section {
                HStack(spacing: 12) {
                    IconTile(systemImage: "person.fill", tint: AppTheme.indigo)
                    TextField("Họ và tên", text: $employeeName)
                        .textContentType(.name)
                }

                HStack(spacing: 12) {
                    IconTile(systemImage: "building.2.fill", tint: AppTheme.blue)
                    TextField("Công ty / bộ phận", text: $companyName)
                }
            } header: {
                AppSectionHeader(title: "Thông tin báo cáo", systemImage: "person.text.rectangle")
            }

            Section {
                DatePicker(
                    selection: startTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("Bắt đầu", systemImage: "sunrise.fill")
                }
                DatePicker(
                    selection: endTimeBinding,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("Kết thúc", systemImage: "sunset.fill")
                }
                Stepper(value: $breakMinutes, in: 0...240, step: 5) {
                    Label("Nghỉ giữa ca: \(breakMinutes) phút", systemImage: "cup.and.saucer.fill")
                }
                Stepper(value: $standardMinutes, in: 60...720, step: 30) {
                    Label("Giờ chuẩn: \(standardMinutes.attendanceDurationText)", systemImage: "clock.fill")
                }
            } header: {
                AppSectionHeader(title: "Giờ làm cố định", systemImage: "clock.badge.checkmark")
            } footer: {
                Text("Tăng ca được tính khi giờ công trong ngày vượt quá giờ chuẩn.")
            }

            Section {
                Toggle(isOn: $worksMonday) { Label("Thứ Hai", systemImage: "2.circle") }
                Toggle(isOn: $worksTuesday) { Label("Thứ Ba", systemImage: "3.circle") }
                Toggle(isOn: $worksWednesday) { Label("Thứ Tư", systemImage: "4.circle") }
                Toggle(isOn: $worksThursday) { Label("Thứ Năm", systemImage: "5.circle") }
                Toggle(isOn: $worksFriday) { Label("Thứ Sáu", systemImage: "6.circle") }
                Toggle(isOn: $worksSaturday) { Label("Thứ Bảy", systemImage: "7.circle") }
                Toggle(isOn: $worksSunday) { Label("Chủ Nhật", systemImage: "1.circle") }
            } header: {
                AppSectionHeader(title: "Ngày làm trong tuần", systemImage: "calendar")
            }

            Section {
                Picker("Giao diện", selection: $appearanceRawValue) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title)
                            .tag(appearance.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityHint("Chọn giao diện theo hệ thống, sáng hoặc tối")
            } header: {
                AppSectionHeader(title: "Giao diện", systemImage: "circle.lefthalf.filled")
            } footer: {
                Text("Chế độ Hệ thống tự đổi theo cài đặt giao diện của iPhone.")
            }

            Section {
                Button(action: exportBackup) {
                    Label("Sao lưu ngày công", systemImage: "square.and.arrow.up")
                }
                Button {
                    isImporting = true
                } label: {
                    Label("Khôi phục ngày công", systemImage: "square.and.arrow.down")
                }
            } header: {
                AppSectionHeader(title: "Sao lưu dữ liệu", systemImage: "externaldrive.fill")
            } footer: {
                Text("Lưu toàn bộ ngày công thành tệp JSON trong Files. Khôi phục sẽ thay thế tất cả ngày công hiện tại; không thay đổi cài đặt. Tệp không mã hóa, hãy lưu ở nơi an toàn.")
            }

            Section {
                Toggle(isOn: $hapticsEnabled) {
                    Label("Rung phản hồi", systemImage: "iphone.radiowaves.left.and.right")
                }

                Label("Dữ liệu được lưu cục bộ trên thiết bị.", systemImage: "lock.shield.fill")
                    .foregroundStyle(.secondary)
            } header: {
                AppSectionHeader(title: "Ứng dụng", systemImage: "gearshape.fill")
            } footer: {
                Text("Ứng dụng không cần tài khoản và không gửi dữ liệu lên máy chủ.")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .tint(AppTheme.indigo)
        .navigationTitle("Cài đặt")
        .onChange(of: appearanceRawValue) { _, _ in
            HapticFeedback.selection(isEnabled: hapticsEnabled)
        }
        .fileExporter(
            isPresented: Binding(
                get: { backupDocument != nil },
                set: { if !$0 { backupDocument = nil } }
            ),
            document: backupDocument,
            contentType: .json,
            defaultFilename: defaultBackupFileName
        ) { result in
            handleExportResult(result)
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .confirmationDialog(
            "Thay thế toàn bộ ngày công hiện tại?",
            isPresented: $isConfirmingRestore,
            titleVisibility: .visible,
            presenting: pendingBackup
        ) { backup in
            Button("Thay thế dữ liệu", role: .destructive) {
                restoreBackup(backup)
            }
            Button("Hủy", role: .cancel) {}
        } message: { backup in
            Text("Bản sao lưu có \(backup.entries.count) ngày công. Thao tác này không thể hoàn tác.")
        }
        .alert(item: $backupMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.text),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: {
                calendar.date(
                    bySettingHour: startHour,
                    minute: startMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { value in
                let components = calendar.dateComponents([.hour, .minute], from: value)
                startHour = components.hour ?? 8
                startMinute = components.minute ?? 0
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: {
                calendar.date(
                    bySettingHour: endHour,
                    minute: endMinute,
                    second: 0,
                    of: .now
                ) ?? .now
            },
            set: { value in
                let components = calendar.dateComponents([.hour, .minute], from: value)
                endHour = components.hour ?? 17
                endMinute = components.minute ?? 0
            }
        )
    }

    private var defaultBackupFileName: String {
        let formatter = DateFormatter()
        formatter.locale = AppLocale.vietnamese
        formatter.dateFormat = "yyyyMMdd-HHmm"
        return "ChamCongHieuIT-saoluu-\(formatter.string(from: .now))"
    }

    private func exportBackup() {
        let entries = (try? modelContext.fetchCount(FetchDescriptor<WorkEntry>())) ?? 0
        guard entries > 0 else {
            backupMessage = BackupMessage(
                title: "Chưa có dữ liệu",
                text: "Hãy tạo ngày công trước khi sao lưu."
            )
            return
        }

        do {
            let fetchDescriptor = FetchDescriptor<WorkEntry>(
                sortBy: [SortDescriptor(\.date, order: .forward)]
            )
            let allEntries = try modelContext.fetch(fetchDescriptor)
            backupDocument = BackupExportDocument(
                backup: AttendanceBackupCodec.makeBackup(from: allEntries)
            )
        } catch {
            backupMessage = BackupMessage(
                title: "Không thể sao lưu",
                text: error.localizedDescription
            )
        }
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case .success:
            HapticFeedback.success(isEnabled: hapticsEnabled)
        case .failure(let error):
            if (error as NSError).code != NSUserCancelledError {
                backupMessage = BackupMessage(
                    title: "Không thể lưu bản sao lưu",
                    text: error.localizedDescription
                )
            }
        }
        backupDocument = nil
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importBackup(from: url)
        case .failure(let error):
            if (error as NSError).code != NSUserCancelledError {
                backupMessage = BackupMessage(
                    title: "Không thể mở tệp sao lưu",
                    text: error.localizedDescription
                )
            }
        }
    }

    private func importBackup(from url: URL) {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            pendingBackup = try AttendanceBackupCodec.decode(data)
            isConfirmingRestore = true
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            backupMessage = BackupMessage(
                title: "Tệp sao lưu không hợp lệ",
                text: error.localizedDescription
            )
        }
    }

    private func restoreBackup(_ backup: AttendanceBackup) {
        do {
            let existing = try modelContext.fetch(FetchDescriptor<WorkEntry>())
            existing.forEach { modelContext.delete($0) }

            let importedEntries = backup.entries.map { record in
                WorkEntry(
                    id: record.id,
                    date: record.date,
                    startTime: record.startTime,
                    endTime: record.endTime,
                    breakMinutes: record.breakMinutes,
                    status: WorkStatus(rawValue: record.statusRawValue) ?? .work,
                    note: record.note,
                    isManuallyEdited: record.isManuallyEdited,
                    updatedAt: record.updatedAt
                )
            }
            importedEntries.forEach { modelContext.insert($0) }
            try modelContext.save()

            pendingBackup = nil
            HapticFeedback.success(isEnabled: hapticsEnabled)
            backupMessage = BackupMessage(
                title: "Đã khôi phục",
                text: "Đã thay thế dữ liệu bằng \(importedEntries.count) ngày công từ bản sao lưu."
            )
        } catch {
            modelContext.rollback()
            HapticFeedback.error(isEnabled: hapticsEnabled)
            backupMessage = BackupMessage(
                title: "Không thể khôi phục",
                text: error.localizedDescription
            )
        }
    }
}

private struct BackupExportDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let backup: AttendanceBackup

    init(backup: AttendanceBackup) {
        self.backup = backup
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        self.backup = try AttendanceBackupCodec.decode(data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try AttendanceBackupCodec.encode(backup)
        return FileWrapper(regularFileWithContents: data)
    }
}

private struct BackupMessage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
}

private struct SettingsHeroCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image("BrandIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
                .shadow(color: AppTheme.indigo.opacity(0.22), radius: 10, y: 5)

            VStack(alignment: .leading, spacing: 5) {
                Text("ChamCongHieuIT")
                    .font(.title3.bold())
                Text("Chấm công cá nhân")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("Riêng tư · Ngoại tuyến", systemImage: "checkmark.shield.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.teal)
            }

            Spacer(minLength: 0)
        }
        .appCard()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
