import Foundation

enum AppLocale {
    static let vietnamese = Locale(identifier: "vi_VN")
}

enum AppStorageKey {
    static let employeeName = "employeeName"
    static let companyName = "companyName"
    static let startHour = "startHour"
    static let startMinute = "startMinute"
    static let endHour = "endHour"
    static let endMinute = "endMinute"
    static let breakMinutes = "breakMinutes"
    static let standardMinutes = "standardMinutes"
    static let worksMonday = "worksMonday"
    static let worksTuesday = "worksTuesday"
    static let worksWednesday = "worksWednesday"
    static let worksThursday = "worksThursday"
    static let worksFriday = "worksFriday"
    static let worksSaturday = "worksSaturday"
    static let worksSunday = "worksSunday"
    static let hapticsEnabled = "hapticsEnabled"
    static let appearance = "appearance"
}

struct ScheduleDefaults {
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    let breakMinutes: Int
    let standardMinutes: Int
    let workingWeekdays: Set<Int>

    func startTime(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: startHour,
            minute: startMinute,
            second: 0,
            of: date
        ) ?? date
    }

    func endTime(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: endHour,
            minute: endMinute,
            second: 0,
            of: date
        ) ?? date
    }
}

struct ReportProfile {
    let employeeName: String
    let companyName: String
    let standardMinutes: Int
}
