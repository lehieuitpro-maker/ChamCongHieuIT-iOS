import Foundation

struct AttendanceBackupEntry: Codable, Hashable {
    var id: UUID
    var date: Date
    var startTime: Date
    var endTime: Date
    var breakMinutes: Int
    var statusRawValue: String
    var note: String
    var isManuallyEdited: Bool
    var updatedAt: Date
}

struct AttendanceBackup: Codable, Hashable {
    var schemaVersion: Int
    var exportedAt: Date
    var entries: [AttendanceBackupEntry]

    static let schemaVersion = 1
}

enum AttendanceBackupError: LocalizedError {
    case unsupportedSchema
    case corruptData

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema:
            "Phiên bản dữ liệu sao lưu không được hỗ trợ."
        case .corruptData:
            "Tệp sao lưu không đọc được hoặc dữ liệu không hợp lệ."
        }
    }
}

enum AttendanceBackupCodec {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    static func makeBackup(from entries: [WorkEntry]) -> AttendanceBackup {
        AttendanceBackup(
            schemaVersion: AttendanceBackup.schemaVersion,
            exportedAt: .now,
            entries: entries.map { entry in
                AttendanceBackupEntry(
                    id: entry.id,
                    date: entry.date,
                    startTime: entry.startTime,
                    endTime: entry.endTime,
                    breakMinutes: entry.breakMinutes,
                    statusRawValue: entry.statusRawValue,
                    note: entry.note,
                    isManuallyEdited: entry.isManuallyEdited,
                    updatedAt: entry.updatedAt
                )
            }
        )
    }

    static func encode(_ backup: AttendanceBackup) throws -> Data {
        try encoder.encode(backup)
    }

    static func decode(_ data: Data) throws -> AttendanceBackup {
        let backup = try decoder.decode(AttendanceBackup.self, from: data)
        guard backup.schemaVersion == AttendanceBackup.schemaVersion else {
            throw AttendanceBackupError.unsupportedSchema
        }
        guard !backup.entries.isEmpty else {
            throw AttendanceBackupError.corruptData
        }
        for entry in backup.entries {
            guard WorkStatus(rawValue: entry.statusRawValue) != nil,
                  entry.breakMinutes >= 0,
                  entry.endTime > entry.startTime else {
                throw AttendanceBackupError.corruptData
            }
        }
        return backup
    }
}
