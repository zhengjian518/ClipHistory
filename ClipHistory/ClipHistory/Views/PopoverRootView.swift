import AppKit
import SwiftUI

struct PopoverRootView: View {
    @StateObject private var viewModel = ClipHistoryViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                SearchBarView(text: $viewModel.searchText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Divider()
                content
                Divider()
                footer
            }

            if showSettings {
                Color.black.opacity(0.18)
                    .onTapGesture { closeSettings() }
                SettingsView(
                    totalCount: viewModel.totalCount,
                    onRetentionChange: {
                        RetentionManager.shared.cleanup()
                        viewModel.refresh()
                    },
                    onClose: { closeSettings() }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .frame(width: 380, height: 520)
        .onAppear { viewModel.refresh() }
    }

    private func closeSettings() {
        withAnimation(.easeOut(duration: 0.2)) { showSettings = false }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.items.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.items, id: \.objectID) { item in
                        ClipCardView(
                            item: item,
                            onPaste: { viewModel.paste(item) },
                            onTogglePin: { withAnimation(.easeOut(duration: 0.2)) { viewModel.togglePin(item) } },
                            onDelete: { withAnimation(.easeOut(duration: 0.2)) { viewModel.delete(item) } }
                        )
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                }
                .padding(12)
                .animation(.easeOut(duration: 0.2), value: viewModel.items)
            }
        }
    }

    private var isSearching: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: isSearching ? "magnifyingglass" : "doc.on.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(isSearching ? "无匹配结果" : "暂无复制记录")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            if !isSearching {
                Text("复制任意内容后将显示在这里")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text("共 \(viewModel.items.count) 条记录")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("退出")

            Button {
                withAnimation(.easeOut(duration: 0.2)) { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("设置")
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
    }
}
