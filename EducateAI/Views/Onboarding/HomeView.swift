import SwiftUI


struct BadgesView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                if store.badges.isEmpty {
                    ContentUnavailableView("No badges yet", systemImage: "rosette", description: Text("Master a chapter, explain your reasoning, or solve a challenge without hints to earn badges."))
                        .padding(.top, 80)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 20) {
                    ForEach(store.badges) { b in
                        VStack(spacing: 10) {
                            Image(systemName: b.symbol).font(.system(size: 44)).foregroundStyle(Theme.sun.gradient)
                                .frame(width: 90, height: 90).background(Circle().fill(Theme.sun.opacity(0.15)))
                            Text(b.title).font(.mHeadline).multilineTextAlignment(.center)
                            Text(b.detail).font(.mCaption).foregroundStyle(Palette.inkSoft).multilineTextAlignment(.center)
                        }
                        .padding().frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.surface))
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(24)
            }
            .background(Palette.paper)
            .navigationTitle("Badges")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
