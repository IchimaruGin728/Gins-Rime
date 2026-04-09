import Foundation

enum Notifier {
    /// 发送 macOS 系统通知
    /// - Parameters:
    ///   - title: 通知标题
    ///   - message: 通知内容
    ///   - sound: 是否播放音效 (默认: Tink)
    static func notify(title: String, message: String, sound: String? = "Tink") {
        var script = "display notification \"\(message)\" with title \"\(title)\""
        if let soundName = sound {
            script += " sound name \"\(soundName)\""
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        
        try? task.run()
    }
}
