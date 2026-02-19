import Foundation
import Combine

// MARK: - Lesson Model

struct Lesson: Identifiable, Equatable {
    let id: String
    let title: String
    let lessonNumber: Int
    let lqURL: URL
    let hqURL: URL
    let duration: TimeInterval

    // Derived from UserDefaults via LessonStore
    var savedPosition: TimeInterval = 0
    var isCompleted: Bool = false
    var downloadState: DownloadState = .notDownloaded
    var downloadProgress: Double = 0

    var localFileURL: URL? {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let file = docDir.appendingPathComponent("lessons/\(id).mp3")
        return FileManager.default.fileExists(atPath: file.path) ? file : nil
    }

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var progressFraction: Double {
        guard duration > 0 else { return 0 }
        return savedPosition / duration
    }

    static func == (lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
}

enum DownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed
}

// MARK: - Build lessons from metadata

extension Lesson {
    static func from(_ meta: LessonMetadata) -> Lesson {
        Lesson(
            id: meta.id,
            title: meta.title,
            lessonNumber: meta.lessonNumber,
            lqURL: meta.lqURL,
            hqURL: meta.hqURL,
            duration: meta.duration
        )
    }
}
