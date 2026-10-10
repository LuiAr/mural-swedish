import SwiftUI
import MuralCore

/// Keeps Han text selectable and word links intact, with an optional reading below it.
struct PinyinHelp: View {
    let text: String
    private let expansion: Binding<Bool>?
    @State private var localExpanded = true

    init(text: String, expanded: Binding<Bool>? = nil) {
        self.text = text; expansion = expanded
    }

    var body: some View {
        let expanded = expansion ?? $localExpanded
        if let reading = MandarinPinyin.reading(text) {
            VStack(spacing: 6) {
                Button { expanded.wrappedValue.toggle() } label: {
                    Label(expanded.wrappedValue ? "Hide pinyin" : "Show pinyin", systemImage: expanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }.buttonStyle(.plain).accessibilityIdentifier("pinyin-toggle")
                if expanded.wrappedValue {
                    // Selectable text intercepts taps on the sibling toggle on iOS 27.
                    Text(reading).font(.callout)
                        .accessibilityIdentifier("pinyin-reading")
                }
            }.foregroundStyle(MuralColor.secondary)
        }
    }
}
