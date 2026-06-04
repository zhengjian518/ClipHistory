import SwiftUI

struct SettingsView: View {
    @AppStorage(RetentionManager.retentionDaysKey) private var retentionDays: Int = 3

    let totalCount: Int
    let onRetentionChange: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("设置")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("保留时长")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Picker("", selection: $retentionDays) {
                    Text("1 天").tag(1)
                    Text("3 天").tag(3)
                    Text("5 天").tag(5)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Text("当前已存储：\(totalCount) 条记录")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
        )
        .onChange(of: retentionDays) { _ in
            onRetentionChange()
        }
    }
}
