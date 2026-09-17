import Foundation
import SwiftData
import SwiftUI

@MainActor
struct ReportView: View {
    @Query(sort: \WorkEntry.date, order: .forward) private var allEntries: [WorkEntry]

    @AppStorage(AppStorageKey.employeeName) private var employeeName = ""
    @AppStorage(AppStorageKey.companyName) private var companyName = ""
    @AppStorage(AppStorageKey.standardMinutes) private var standardMinutes = 480
    @AppStorage(AppStorageKey.hapticsEnabled) private var hapticsEnabled = true

    @State private var selectedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var generatedPDF: GeneratedPDF?
    @State private var exportFailure: ExportFailure?

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
                ReportSummaryCard(
                    workedDays: workedDays,
                    totalMinutes: totalMinutes,
                    overtimeMinutes: overtimeMinutes
                )
            } header: {
                AppSectionHeader(title: "Tổng hợp", systemImage: "chart.pie.fill")
            }
            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        IconTile(
                            systemImage: generatedPDF == nil ? "doc.text.fill" : "checkmark.seal.fill",
                            tint: generatedPDF == nil ? AppTheme.indigo : AppTheme.teal
                        )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(generatedPDF == nil ? "Báo cáo PDF theo tháng" : "Báo cáo đã sẵn sàng")
                                .font(.headline)
                            Text(generatedPDF == nil ? "Tạo bảng công để lưu hoặc chia sẻ." : "Bạn có thể chia sẻ hoặc tạo lại khi cần.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        createPDF()
                    } label: {
                        Label(
                            generatedPDF == nil ? "Tạo báo cáo PDF" : "Tạo lại báo cáo PDF",
                            systemImage: "doc.badge.plus"
                        )
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    if let generatedPDF {
                        ShareLink(item: generatedPDF.url) {
                            Label("Chia sẻ báo cáo", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(TintedActionButtonStyle(tint: AppTheme.teal))

                        Button(role: .destructive) {
                            removeGeneratedPDF(feedback: true)
                        } label: {
                            Label("Xóa báo cáo đã tạo", systemImage: "trash")
                        }
                        .buttonStyle(TintedActionButtonStyle(tint: .red))
                    }
                }
                .appCard()
            } header: {
                AppSectionHeader(title: "Xuất báo cáo", systemImage: "square.and.arrow.up")
            } footer: {
                Text("PDF có thể lưu vào Files hoặc gửi qua AirDrop, email và các ứng dụng khác.")
            }
            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            Section {
                if monthEntries.isEmpty {
                    ContentUnavailableView(
                        "Không có dữ liệu",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Hãy tạo dữ liệu chấm công cho tháng này trước.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .appCard()
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(monthEntries) { entry in
                        HStack(spacing: 12) {
                            IconTile(
                                systemImage: entry.status.systemImage,
                                tint: entry.status.tintColor
                            )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date.vietnameseFullDate)
                                    .font(.subheadline.weight(.medium))
                                Text(entry.status.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.totalMinutes.attendanceDurationText)
                                .font(.subheadline.weight(.semibold))
                        }
                        .appCard(padding: 12)
                        .listRowInsets(.init(top: 5, leading: 16, bottom: 5, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            } header: {
                AppSectionHeader(
                    title: "Dữ liệu trong báo cáo",
                    systemImage: "doc.text.magnifyingglass"
                )
            }
        }
        .listStyle(.plain)
        .listSectionSpacing(14)
        .scrollContentBackground(.hidden)
        .background(AppTheme.pageBackground)
        .navigationTitle("Báo cáo")
        .onChange(of: selectedMonth) { _, _ in
            removeGeneratedPDF()
        }
        .onChange(of: reportFingerprint) { _, _ in
            removeGeneratedPDF()
        }
        .alert(item: $exportFailure) { failure in
            Alert(
                title: Text("Không thể tạo PDF"),
                message: Text(failure.message),
                dismissButton: .default(Text("OK"))
            )
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

    private var reportFingerprint: String {
        monthEntries.map {
            "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSinceReferenceDate)"
        }
        .joined(separator: "|")
    }

    @MainActor
    private func createPDF() {
        guard !monthEntries.isEmpty else {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            exportFailure = ExportFailure(message: "Tháng đã chọn chưa có dữ liệu chấm công.")
            return
        }

        let profile = ReportProfile(
            employeeName: employeeName,
            companyName: companyName,
            standardMinutes: standardMinutes
        )

        removeGeneratedPDF()

        do {
            let url = try PDFReportGenerator.generate(
                month: selectedMonth,
                entries: monthEntries,
                profile: profile
            )
            generatedPDF = GeneratedPDF(url: url)
            HapticFeedback.success(isEnabled: hapticsEnabled)
        } catch {
            HapticFeedback.error(isEnabled: hapticsEnabled)
            exportFailure = ExportFailure(message: error.localizedDescription)
        }
    }

    private func removeGeneratedPDF(feedback: Bool = false) {
        guard let generatedPDF else { return }
        try? FileManager.default.removeItem(at: generatedPDF.url)
        self.generatedPDF = nil
        if feedback {
            HapticFeedback.selection(isEnabled: hapticsEnabled)
        }
    }
}

private struct ReportSummaryCard: View {
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

private struct GeneratedPDF: Identifiable {
    let url: URL
    var id: URL { url }
}

private struct ExportFailure: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    NavigationStack {
        ReportView()
    }
    .modelContainer(for: WorkEntry.self, inMemory: true)
}
