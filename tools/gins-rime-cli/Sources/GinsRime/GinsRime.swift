import ArgumentParser

@main
struct GinsRime: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gins-rime",
        abstract: "Gins-Rime: macOS 鼠须管 RIME 方案管理工具",
        version: "0.1.0",
        subcommands: [
            Deploy.self,
            Update.self,
            Sync.self,
            Customize.self,
            Status.self,
        ],
        defaultSubcommand: Status.self
    )
}
