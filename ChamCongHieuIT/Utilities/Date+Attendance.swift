import Foundation

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }

    func addingMonths(_ value: Int, to date: Date) -> Date {
        self.date(byAdding: .month, value: value, to: startOfMonth(for: date)) ?? date
    }

    func datesInMonth(containing date: Date) -> [Date] {
        let start = startOfMonth(for: date)
        let next = addingMonths(1, to: start)
        var result: [Date] = []
        var cursor = start

        while cursor < next {
            result.append(cursor)
            guard let followingDay = self.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = followingDay
        }

        return result
    }

    func isDate(_ date: Date, inSameMonthAs otherDate: Date) -> Bool {
        isDate(date, equalTo: otherDate, toGranularity: .month)
    }

    func combining(day: Date, time: Date) -> Date {
        let timeComponents = dateComponents([.hour, .minute], from: time)
        return self.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }
}

extension Int {
    var attendanceDurationText: String {
        let safeValue = Swift.max(0, self)
        let hours = safeValue / 60
        let minutes = safeValue % 60
        return minutes == 0 ? "\(hours) giờ" : "\(hours) giờ \(minutes) phút"
    }

    var attendanceCompactDuration: String {
        let safeValue = Swift.max(0, self)
        let hours = safeValue / 60
        let minutes = safeValue % 60
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)p"
    }
}

extension Date {
    var vietnameseMonthYear: String {
        formatted(
            Date.FormatStyle()
                .month(.wide)
                .year()
                .locale(AppLocale.vietnamese)
        )
    }

    var vietnameseDayNumber: String {
        formatted(
            Date.FormatStyle()
                .day()
                .locale(AppLocale.vietnamese)
        )
    }

    var vietnameseWeekday: String {
        formatted(
            Date.FormatStyle()
                .weekday(.wide)
                .locale(AppLocale.vietnamese)
        )
    }

    var vietnameseFullDate: String {
        formatted(
            Date.FormatStyle()
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
                .locale(AppLocale.vietnamese)
        )
    }

    var vietnameseShortTime: String {
        formatted(
            Date.FormatStyle(date: .omitted, time: .shortened)
                .locale(AppLocale.vietnamese)
        )
    }
}
