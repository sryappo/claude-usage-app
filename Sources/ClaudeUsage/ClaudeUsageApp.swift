import SwiftUI

@main
struct ClaudeUsageApp: App {
    @State private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.menuBarTitle) {
            UsageView(viewModel: viewModel)
                .onAppear {
                    viewModel.startPolling()
                }
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 280, height: 300)
    }
}
