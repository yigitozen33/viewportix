import Foundation

/// `VPX-NNNN` codes shown under our alert texts (DESIGN.md §4 K8, HOME-13, PW-09), mono and
/// selectable so they can be pasted into a bug report. Catalogue: `docs/hata-kodlari.md`.
/// 00xx file reading, 01xx saving, 02xx sync, 03xx engines.
public enum ErrorCode: Int, CaseIterable, Sendable {
    case fileMissing = 1
    case jsonUnreadable = 42
    case projectFileMissing = 43
    case newerSchema = 44
    case readPermission = 50
    case devicesUnreadable = 60
    case readFailed = 99

    case diskFull = 101
    case writePermission = 102
    case nameTaken = 103
    case draftCreateFailed = 110
    case draftTrashFailed = 111
    case duplicateFailed = 120
    case writeFailed = 199

    case syncAgentBlocked = 201
    case syncEventLost = 202

    case webContentCrashed = 301
    case snapshotFailed = 302

    /// "VPX-0042"
    public var code: String { String(format: "VPX-%04d", rawValue) }

    /// Short reason in the catalogue's words.
    public var reason: String {
        switch self {
        case .fileMissing: "Dosya bulunamadı"
        case .jsonUnreadable: "JSON çözümlenemedi"
        case .projectFileMissing: "project.json eksik"
        case .newerSchema: "Dosya sürümü daha yeni"
        case .readPermission: "Okuma izni yok"
        case .devicesUnreadable: "Cihaz listesi okunamadı"
        case .readFailed: "Dosya okunamadı"
        case .diskFull: "Diskte yer yok"
        case .writePermission: "Yazma izni yok"
        case .nameTaken: "Aynı adlı dosya var"
        case .draftCreateFailed: "Taslak oluşturulamadı"
        case .draftTrashFailed: "Taslak silinemedi"
        case .duplicateFailed: "Kopya yazılamadı"
        case .writeFailed: "Dosya yazılamadı"
        case .syncAgentBlocked: "Senkron ajanı sayfaya giremedi"
        case .syncEventLost: "Senkron olayı ulaşmadı"
        case .webContentCrashed: "Web içeriği süreci kapandı"
        case .snapshotFailed: "Ekran görüntüsü alınamadı"
        }
    }

    /// The accessory line: "VPX-0042 · JSON çözümlenemedi", plus the system's detail when useful.
    public func line(detail: String? = nil) -> String {
        ([code, reason] + [detail].compactMap(\.self)).joined(separator: " · ")
    }

    /// Why reading a package failed.
    public static func reading(_ error: Error) -> ErrorCode {
        if case ProjectCodingError.unsupportedSchemaVersion = error { return .newerSchema }
        if error is DecodingError { return .jsonUnreadable }
        let error = error as NSError
        guard error.domain == NSCocoaErrorDomain else { return .readFailed }
        switch error.code {
        case NSFileReadNoSuchFileError, NSFileNoSuchFileError: return .fileMissing
        case NSFileReadNoPermissionError: return .readPermission
        case NSFileReadCorruptFileError: return .projectFileMissing
        default: return .readFailed
        }
    }

    /// Why writing failed: disk full and no permission get their own texts (PW-09).
    public static func writing(_ error: Error) -> ErrorCode {
        let error = error as NSError
        let underlying = error.userInfo[NSUnderlyingErrorKey] as? NSError
        if error.domain == NSCocoaErrorDomain {
            switch error.code {
            case NSFileWriteOutOfSpaceError: return .diskFull
            case NSFileWriteNoPermissionError, NSFileWriteVolumeReadOnlyError: return .writePermission
            case NSFileWriteFileExistsError: return .nameTaken
            default: break
            }
        }
        if let posix = (error.domain == NSPOSIXErrorDomain ? error : underlying), posix.domain == NSPOSIXErrorDomain {
            if posix.code == Int(ENOSPC) { return .diskFull }
            if posix.code == Int(EACCES) || posix.code == Int(EPERM) || posix.code == Int(EROFS) { return .writePermission }
        }
        return .writeFailed
    }
}
