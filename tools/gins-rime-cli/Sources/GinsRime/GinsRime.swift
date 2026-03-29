import ArgumentParser

@main
struct GinsRime: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "gins-rime",
        abstract: "Gins-Rime macOS 管理工具",
        version: "1.0.0",
        subcommands: [
            Deploy.self,
            Update.self,
            Sync.self,
            Status.self,
        ],
        defaultSubcommand: Status.self
    )
}
