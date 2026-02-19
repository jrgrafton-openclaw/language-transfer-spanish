import Foundation
import Combine

// MARK: - DownloadManager

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    private var session: URLSession!
    private var activeTasks: [String: URLSessionDownloadTask] = [:]
    private var progressHandlers: [String: (Double) -> Void] = [:]
    private var completionHandlers: [String: (Result<URL, Error>) -> Void] = [:]

    // Map taskIdentifier -> lessonId
    private var taskToLessonId: [Int: String] = [:]

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.grafton.languagetransfer.spanish.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Lessons Directory

    var lessonsDirectory: URL {
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docDir.appendingPathComponent("lessons")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func localFileURL(for lessonId: String) -> URL {
        lessonsDirectory.appendingPathComponent("\(lessonId).mp3")
    }

    func isDownloaded(_ lessonId: String) -> Bool {
        FileManager.default.fileExists(atPath: localFileURL(for: lessonId).path)
    }

    func isDownloading(_ lessonId: String) -> Bool {
        activeTasks[lessonId] != nil
    }

    // MARK: - Download

    func download(
        lesson: Lesson,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let lessonId = lesson.id
        guard activeTasks[lessonId] == nil else { return }

        progressHandlers[lessonId] = progress
        completionHandlers[lessonId] = completion

        let task = session.downloadTask(with: lesson.lqURL)
        activeTasks[lessonId] = task
        taskToLessonId[task.taskIdentifier] = lessonId
        task.resume()
    }

    func cancelDownload(for lessonId: String) {
        activeTasks[lessonId]?.cancel()
        activeTasks[lessonId] = nil
        progressHandlers[lessonId] = nil
        completionHandlers[lessonId] = nil
    }

    func deleteLocalFile(for lessonId: String) {
        let url = localFileURL(for: lessonId)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task { @MainActor in
            guard let lessonId = taskToLessonId[downloadTask.taskIdentifier] else { return }

            let dest = localFileURL(for: lessonId)
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.moveItem(at: location, to: dest)
                completionHandlers[lessonId]?(.success(dest))
            } catch {
                completionHandlers[lessonId]?(.failure(error))
            }

            activeTasks[lessonId] = nil
            progressHandlers[lessonId] = nil
            completionHandlers[lessonId] = nil
            taskToLessonId[downloadTask.taskIdentifier] = nil
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor in
            guard let lessonId = taskToLessonId[downloadTask.taskIdentifier] else { return }
            let progress = totalBytesExpectedToWrite > 0
                ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
                : 0
            progressHandlers[lessonId]?(progress)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        Task { @MainActor in
            guard let lessonId = taskToLessonId[task.taskIdentifier] else { return }
            completionHandlers[lessonId]?(.failure(error))
            activeTasks[lessonId] = nil
            progressHandlers[lessonId] = nil
            completionHandlers[lessonId] = nil
            taskToLessonId[task.taskIdentifier] = nil
        }
    }
}
