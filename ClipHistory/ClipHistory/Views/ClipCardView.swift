import SwiftUI
import AppKit

struct ClipCardView: View {
    let item: ClipItemEntity
    let onPaste: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void

    @State private var pinHover = false
    @State private var deleteHover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 2) {
                Spacer()
                pinButton
                deleteButton
            }
            .frame(height: 20)

            contentBody

            Text(sourceLine)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(item.isPinned
                      ? Color("PinnedCardBackground")
                      : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture { onPaste() }
    }

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(item.isPinned || pinHover ? Color.accentColor : Color.secondary)
                .frame(width: 28, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { pinHover = $0 }
        .help(item.isPinned ? "取消置顶" : "置顶")
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 12))
                .foregroundStyle(deleteHover ? Color.red : Color.secondary)
                .frame(width: 28, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { deleteHover = $0 }
        .help("删除")
    }

    @ViewBuilder
    private var contentBody: some View {
        if item.typeRaw == ClipItemType.image.rawValue,
           let data = item.imageData,
           let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage.thumbnail(maxHeight: 80))
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .frame(maxWidth: .infinity, alignment: .leading)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            Text(item.content ?? "")
                .font(.system(size: 14))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sourceLine: String {
        "来自 \(appName(from: item.appSource)) · \(timeString(item.createdAt))"
    }

    private func appName(from bundleID: String?) -> String {
        guard let bundleID else { return "未知来源" }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return FileManager.default.displayName(atPath: url.path)
                .replacingOccurrences(of: ".app", with: "")
        }
        return bundleID
    }

    private func timeString(_ date: Date?) -> String {
        guard let date else { return "" }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "M月d日 HH:mm"
        }
        return formatter.string(from: date)
    }
}
