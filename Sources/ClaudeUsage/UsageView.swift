import SwiftUI

struct UsageView: View {
    let viewModel: UsageViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerSection
            Divider()

            if let error = viewModel.errorMessage {
                errorSection(error)
            } else if let usage = viewModel.usage {
                usageBucketsSection(usage)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity)
                    .padding()
            }

            Divider()
            footerSection
        }
        .padding(12)
        .frame(width: 280)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            Text("Claude Usage")
                .font(.headline)
            Spacer()
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private func errorSection(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Error", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.subheadline.weight(.medium))
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func usageBucketsSection(_ usage: UsageResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let fiveHour = usage.fiveHour {
                bucketRow(
                    label: "Session (5h)",
                    utilization: fiveHour.utilization,
                    resetIn: viewModel.formattedResetTime(fiveHour)
                )
            }

            if let sevenDay = usage.sevenDay {
                bucketRow(
                    label: "Weekly",
                    utilization: sevenDay.utilization,
                    resetIn: viewModel.formattedResetTime(sevenDay)
                )
            }

            if let opus = usage.sevenDayOpus, opus.utilization > 0 {
                bucketRow(
                    label: "Weekly (Opus)",
                    utilization: opus.utilization,
                    resetIn: viewModel.formattedResetTime(opus)
                )
            }

            if let extra = usage.extraUsage, extra.isEnabled == true {
                Divider()
                extraUsageRow(extra)
            }
        }
    }

    private func bucketRow(label: String, utilization: Double, resetIn: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(utilization))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(colorForUtilization(utilization))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorForUtilization(utilization))
                        .frame(width: geo.size.width * min(utilization / 100, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Resets in \(resetIn)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }

    private func extraUsageRow(_ extra: ExtraUsage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Extra Usage")
                    .font(.subheadline.weight(.medium))
                if let used = extra.usedCredits, let limit = extra.monthlyLimit {
                    Text("$\(String(format: "%.2f", used / 100)) / $\(String(format: "%.2f", limit / 100))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let util = extra.utilization {
                Text("\(Int(util))%")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(colorForUtilization(util))
            }
        }
    }

    private var footerSection: some View {
        HStack {
            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(lastUpdated, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Refresh") {
                Task { await viewModel.refresh() }
            }
            .buttonStyle(.borderless)
            .font(.caption)

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
    }

    // MARK: - Helpers

    private func colorForUtilization(_ value: Double) -> Color {
        switch value {
        case 0..<50: return .green
        case 50..<80: return .yellow
        case 80..<100: return .orange
        default: return .red
        }
    }
}
