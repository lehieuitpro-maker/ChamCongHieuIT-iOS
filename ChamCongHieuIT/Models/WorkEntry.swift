import Foundation
import SwiftData

enum WorkStatus: String, CaseIterable, Codable, Identifiable, Hashable {
    case work
    case paidLeave
    case unpaidLeave
    case holiday

    var id: String { rawValue }

    var title: String {
        switch self {
        case .work:
            "Đi làm"
        case .paidLeave:
            "Nghỉ phép"
        case .unpaidLeave:
            "Nghỉ không lương"
        case .holiday:
            "Nghỉ lễ"
        }
    }

    var systemImage: String {
        switch self {
        case .work:
            "checkmark.circle.fill"
        case .paidLeave:
            "person.crop.circle.badge.checkmark"
        case .unpaidLeave:
            "minus.circle.fill"
        case .holiday:
            "calendar.badge.exclamationmark"
        }
    }
}

@Model
final class WorkEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
    var statusRawValue: String
    var note: String
    var isManuallyEdited: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        startTime: Date,
        endTime: Date,
        breakMinutes: Int,
        status: WorkStatus = .work,
        note: String = "",
        isManuallyEdited: Bool = false,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.startTime = startTime
        self.endTime = endTime
        self.breakMinutes = max(0, breakMinutes)
        self.statusRawValue = status.rawValue
        self.note = note
        self.isManuallyEdited = isManuallyEdited
        self.updatedAt = updatedAt
    }

    var status: WorkStatus {
        get { WorkStatus(rawValue: statusRawValue) ?? .work }
        set { statusRawValue = newValue.rawValue }
    }

    var totalMinutes: Int {
        guard status == .work else { return 0 }
        let elapsed = Int(endTime.timeIntervalSince(startTime) / 60)
        return max(0, elapsed - breakMinutes)
    }
}
