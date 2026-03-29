import Foundation
import SwiftUI

@MainActor
@Observable
final class UsageViewModel {
    var usage: UsageResponse?
    var errorMessage: String?
    var lastUpdated: Date?
    var isLoading = false

    private let service = UsageService()
    private var timer: Timer?

    var menuBarTitle: String {
        guard let usage else {
            if errorMessage != nil { return "⚠️" }
            return "◉ …"
        }

        let session = usage.fiveHour?.utilization ?? 0
        let icon = statusIcon(for: session)
        return "\(icon) \(Int(session))%"
    }

    func startPolling(interval: TimeInterval = 180) {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.refresh() }
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            usage = try await service.fetchUsage()
            errorMessage = nil
            lastUpdated = Date()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func statusIcon(for utilization: Double) -> String {
        switch utilization {
        case 0..<50: return "◉"   // green zone
        case 50..<80: return "◉"  // caution
        case 80..<100: return "⚠️" // warning
        default: return "🔴"       // at/over limit
        }
    }

    func formattedResetTime(_ bucket: UsageBucket?) -> String {
        guard let date = bucket?.resetsAtDate else { return "—" }
        let now = Date()
        let diff = date.timeIntervalSince(now)
        if diff <= 0 { return "now" }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
