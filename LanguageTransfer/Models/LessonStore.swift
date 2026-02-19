import Foundation
import Combine
import SwiftUI

// MARK: - LessonStore

@MainActor
final class LessonStore: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var currentLesson: Lesson? = nil
    @Published var isPlayerPresented: Bool = false

    // Computed: lesson in progress (has saved position but not completed)
    var lessonInProgress: Lesson? {
        lessons.first { $0.savedPosition > 5 && !$0.isCompleted }
    }

    init() {
        buildLessons()
    }

    private func buildLessons() {
        lessons = SpanishLessons.all.map { meta in
            var lesson = Lesson.from(meta)
            lesson.savedPosition = loadPosition(for: meta.id)
            lesson.isCompleted = loadCompleted(for: meta.id)
            lesson.downloadState = localFileExists(for: meta.id) ? .downloaded : .notDownloaded
            return lesson
        }
    }

    // MARK: - Persistence

    func savePosition(_ position: TimeInterval, for lessonId: String) {
        UserDefaults.standard.set(position, forKey: "lesson_position_\(lessonId)")
        if let idx = lessons.firstIndex(where: { $0.id == lessonId }) {
            lessons[idx].savedPosition = position
        }
    }

    func markCompleted(_ lessonId: String) {
        UserDefaults.standard.set(true, forKey: "lesson_completed_\(lessonId)")
        if let idx = lessons.firstIndex(where: { $0.id == lessonId }) {
            lessons[idx].isCompleted = true
        }
    }

    func loadPosition(for lessonId: String) -> TimeInterval {
        UserDefaults.standard.double(forKey: "lesson_position_\(lessonId)")
    }

    func loadCompleted(for lessonId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "lesson_completed_\(lessonId)")
    }

    func localFileExists(for lessonId: String) -> Bool {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let file = docDir.appendingPathComponent("lessons/\(lessonId).mp3")
        return FileManager.default.fileExists(atPath: file.path)
    }

    func updateDownloadState(_ state: DownloadState, for lessonId: String) {
        if let idx = lessons.firstIndex(where: { $0.id == lessonId }) {
            lessons[idx].downloadState = state
            if case .downloading(let progress) = state {
                lessons[idx].downloadProgress = progress
            }
        }
    }

    // MARK: - Navigation

    func openLesson(_ lesson: Lesson) {
        currentLesson = lesson
        isPlayerPresented = true
    }

    func nextLesson(after lesson: Lesson) -> Lesson? {
        guard let idx = lessons.firstIndex(of: lesson), idx + 1 < lessons.count else { return nil }
        return lessons[idx + 1]
    }

    func previousLesson(before lesson: Lesson) -> Lesson? {
        guard let idx = lessons.firstIndex(of: lesson), idx > 0 else { return nil }
        return lessons[idx - 1]
    }
}
