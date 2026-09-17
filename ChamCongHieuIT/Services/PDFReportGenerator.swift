import Foundation
import UIKit

@MainActor
enum PDFReportGenerator {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
    private static let margin: CGFloat = 40
    private static let rowHeight: CGFloat = 25

    static func generate(
        month: Date,
        entries: [WorkEntry],
        profile: ReportProfile
    ) throws -> URL {
        let rows = entries
            .sorted { $0.date < $1.date }
            .map { ReportRow(entry: $0, standardMinutes: profile.standardMinutes) }

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Bảng chấm công",
            kCGPDFContextAuthor as String: profile.employeeName.isEmpty
                ? "ChamCongHieuIT"
                : profile.employeeName
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        let data = renderer.pdfData { context in
            var cursorY = margin
            context.beginPage()
            cursorY = drawDocumentHeader(
                month: month,
                profile: profile,
                at: cursorY
            )
            cursorY = drawTableHeader(at: cursorY)

            for row in rows {
                if cursorY + rowHeight > pageBounds.height - margin - 75 {
                    context.beginPage()
                    cursorY = margin
                    cursorY = drawContinuationHeader(month: month, at: cursorY)
                    cursorY = drawTableHeader(at: cursorY)
                }

                draw(row: row, at: cursorY)
                cursorY += rowHeight
            }

            if cursorY + 90 > pageBounds.height - margin {
                context.beginPage()
                cursorY = margin
            }

            drawSummary(rows: rows, at: cursorY + 18)
        }

        let monthComponents = Calendar(identifier: .gregorian)
            .dateComponents([.year, .month], from: month)
        let monthCode = String(
            format: "%04d-%02d",
            monthComponents.year ?? 0,
            monthComponents.month ?? 0
        )
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ChamCongHieuIT-\(monthCode).pdf")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func drawDocumentHeader(
        month: Date,
        profile: ReportProfile,
        at y: CGFloat
    ) -> CGFloat {
        drawText(
            "BẢNG CHẤM CÔNG",
            in: CGRect(x: margin, y: y, width: pageBounds.width - margin * 2, height: 30),
            font: .boldSystemFont(ofSize: 20),
            alignment: .center
        )

        let monthText = month.vietnameseMonthYear
        drawText(
            monthText,
            in: CGRect(x: margin, y: y + 30, width: pageBounds.width - margin * 2, height: 22),
            font: .systemFont(ofSize: 12),
            alignment: .center
        )

        drawText(
            "Họ và tên: \(profile.employeeName.isEmpty ? "Chưa thiết lập" : profile.employeeName)",
            in: CGRect(x: margin, y: y + 65, width: pageBounds.width - margin * 2, height: 18),
            font: .systemFont(ofSize: 11)
        )
        drawText(
            "Công ty / bộ phận: \(profile.companyName.isEmpty ? "Chưa thiết lập" : profile.companyName)",
            in: CGRect(x: margin, y: y + 84, width: pageBounds.width - margin * 2, height: 18),
            font: .systemFont(ofSize: 11)
        )
        return y + 115
    }

    private static func drawContinuationHeader(month: Date, at y: CGFloat) -> CGFloat {
        let monthText = month.vietnameseMonthYear
        drawText(
            "BẢNG CHẤM CÔNG – \(monthText) (tiếp)",
            in: CGRect(x: margin, y: y, width: pageBounds.width - margin * 2, height: 24),
            font: .boldSystemFont(ofSize: 14),
            alignment: .center
        )
        return y + 34
    }

    private static func drawTableHeader(at y: CGFloat) -> CGFloat {
        let headers = ["Ngày", "Vào", "Ra", "Nghỉ", "Giờ công", "Tăng ca", "Trạng thái"]
        let widths: [CGFloat] = [70, 52, 52, 52, 67, 67, 155]
        var x = margin

        UIColor.systemIndigo.withAlphaComponent(0.12).setFill()
        UIRectFill(CGRect(x: margin, y: y, width: widths.reduce(0, +), height: rowHeight))

        for (index, header) in headers.enumerated() {
            let rect = CGRect(x: x, y: y, width: widths[index], height: rowHeight)
            stroke(rect)
            drawText(
                header,
                in: rect.insetBy(dx: 3, dy: 5),
                font: .boldSystemFont(ofSize: 9),
                alignment: .center
            )
            x += widths[index]
        }

        return y + rowHeight
    }

    private static func draw(row: ReportRow, at y: CGFloat) {
        let values = [
            row.date,
            row.start,
            row.end,
            row.breakText,
            row.total,
            row.overtime,
            row.status + (row.isEdited ? " *" : "")
        ]
        let widths: [CGFloat] = [70, 52, 52, 52, 67, 67, 155]
        var x = margin

        for (index, value) in values.enumerated() {
            let rect = CGRect(x: x, y: y, width: widths[index], height: rowHeight)
            stroke(rect)
            drawText(
                value,
                in: rect.insetBy(dx: 3, dy: 5),
                font: .systemFont(ofSize: 8.5),
                alignment: index == values.count - 1 ? .left : .center
            )
            x += widths[index]
        }
    }

    private static func drawSummary(rows: [ReportRow], at y: CGFloat) {
        let workedDays = rows.filter { $0.totalMinutes > 0 }.count
        let totalMinutes = rows.reduce(0) { $0 + $1.totalMinutes }
        let overtimeMinutes = rows.reduce(0) { $0 + $1.overtimeMinutes }

        drawText(
            "Tổng ngày có công: \(workedDays) ngày",
            in: CGRect(x: margin, y: y, width: 250, height: 20),
            font: .boldSystemFont(ofSize: 11)
        )
        drawText(
            "Tổng thời gian: \(totalMinutes.attendanceDurationText)",
            in: CGRect(x: margin, y: y + 22, width: 250, height: 20),
            font: .boldSystemFont(ofSize: 11)
        )
        drawText(
            "Tổng tăng ca: \(overtimeMinutes.attendanceDurationText)",
            in: CGRect(x: margin, y: y + 44, width: 250, height: 20),
            font: .boldSystemFont(ofSize: 11)
        )

        drawText(
            "Người chấm công",
            in: CGRect(x: pageBounds.width - margin - 180, y: y, width: 180, height: 20),
            font: .boldSystemFont(ofSize: 11),
            alignment: .center
        )
        drawText(
            "(Ký và ghi rõ họ tên)",
            in: CGRect(x: pageBounds.width - margin - 180, y: y + 20, width: 180, height: 20),
            font: .italicSystemFont(ofSize: 9),
            alignment: .center
        )

        drawText(
            "* Bản ghi đã được chỉnh sửa thủ công.",
            in: CGRect(x: margin, y: y + 68, width: 300, height: 18),
            font: .italicSystemFont(ofSize: 8),
            color: .darkGray
        )
    }

    private static func stroke(_ rect: CGRect) {
        let path = UIBezierPath(rect: rect)
        UIColor.systemGray3.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor = .black,
        alignment: NSTextAlignment = .left
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail

        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
    }
}

private struct ReportRow {
    let date: String
    let start: String
    let end: String
    let breakText: String
    let total: String
    let overtime: String
    let status: String
    let isEdited: Bool
    let totalMinutes: Int
    let overtimeMinutes: Int

    init(entry: WorkEntry, standardMinutes: Int) {
        date = entry.date.formatted(
            Date.FormatStyle()
                .day(.twoDigits)
                .month(.twoDigits)
                .year()
                .locale(Locale(identifier: "vi_VN"))
        )
        start = entry.status == .work
            ? entry.startTime.vietnameseShortTime
            : "—"
        end = entry.status == .work
            ? entry.endTime.vietnameseShortTime
            : "—"
        breakText = entry.status == .work ? "\(entry.breakMinutes)p" : "—"
        total = entry.totalMinutes.attendanceDurationText
        let overtimeValue = max(0, entry.totalMinutes - standardMinutes)
        overtimeMinutes = overtimeValue
        overtime = overtimeValue.attendanceDurationText
        let trimmedNote = entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
        status = trimmedNote.isEmpty
            ? entry.status.title
            : "\(entry.status.title) – \(trimmedNote)"
        isEdited = entry.isManuallyEdited
        totalMinutes = entry.totalMinutes
    }
}
