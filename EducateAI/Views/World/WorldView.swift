import SwiftUI

struct WorldView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var world = WorldModel()
    @State private var activeChapter: ChapterRef?
    @State private var sheet: WorldSheet?
    @State private var toast: String?
    @State private var celebrate: UUID?
    @State private var showList = false
    @FocusState private var focused: Bool
    var courseID: UUID

    struct ChapterRef: Identifiable { var id: UUID }
    enum WorldSheet: String, Identifiable { case library, pond, campfire, settings; var id: String { rawValue } }

    private static let chapterSpots: [CGPoint] = [CGPoint(x: 0.20, y: 0.66), CGPoint(x: 0.50, y: 0.32), CGPoint(x: 0.80, y: 0.62), CGPoint(x: 0.62, y: 0.12), CGPoint(x: 0.10, y: 0.40)]

    var body: some View {
        if let course = store.course(courseID) {
            content(course)
        } else {
            ContentUnavailableView("Course not found", systemImage: "map")
        }
    }

    private func pois(_ course: Course) -> [PointOfInterest] {
        var out: [PointOfInterest] = course.chapters.prefix(5).enumerated().map { i, ch in
            let st = store.chapterProgress(course, ch).status
            return PointOfInterest(id: ch.id.uuidString, kind: .chapter(ch.id), position: Self.chapterSpots[i], title: ch.locationName,
                                   subtitle: st == .locked ? "Locked · master Chapter \(i) first" : "Chapter \(i + 1): \(ch.title)",
                                   symbol: ch.theme.symbol, color: Theme.themeColor(ch.theme), number: i + 1)
        }
        out.append(PointOfInterest(id: "library", kind: .library, position: CGPoint(x: 0.13, y: 0.18), title: "The Library", subtitle: "Ask privately or share a concern", symbol: "books.vertical.fill", color: Theme.coral))
        out.append(PointOfInterest(id: "pond", kind: .pond, position: CGPoint(x: 0.56, y: 0.78), title: "Reflection Pond", subtitle: "Journal what you learned", symbol: "drop.fill", color: Theme.sky))
        out.append(PointOfInterest(id: "campfire", kind: .campfire, position: CGPoint(x: 0.87, y: 0.22), title: "Review Campfire", subtitle: "Flashcards and spaced review", symbol: "flame.fill", color: Theme.sun))
        return out
    }

    private func content(_ course: Course) -> some View {
        let points = pois(course)
        let near = points.min { world.distance(to: $0.position) < world.distance(to: $1.position) }.flatMap { world.distance(to: $0.position) < 90 ? $0 : nil }

        return GeometryReader { geo in
            ZStack {
                MapBackground(chapterSpots: Array(Self.chapterSpots.prefix(course.chapters.count)), extraSpots: points.filter { if case .chapter = $0.kind { return false }; return true }.map(\.position), animate: !store.settings.reduceMotion && activeChapter == nil && sheet == nil)
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { v in
                        world.target = CGPoint(x: v.location.x / geo.size.width, y: v.location.y / geo.size.height)
                    })

                ForEach(points) { poi in
                    LocationMarker(poi: poi, status: status(of: poi, course), npc: npc(of: poi, course), isNear: near?.id == poi.id, celebrating: celebrate.map { $0.uuidString == poi.id } ?? false, still: store.settings.reduceMotion)
                        .position(x: poi.position.x * geo.size.width, y: poi.position.y * geo.size.height)
                        .onTapGesture { world.target = CGPoint(x: poi.position.x, y: poi.position.y + 0.06) }
                }

                if let t = world.target {
                    Circle().stroke(.white.opacity(0.8), lineWidth: 3).frame(width: 26, height: 12)
                        .position(x: t.x * geo.size.width, y: t.y * geo.size.height + 22)
                        .allowsHitTesting(false)
                }

                WalkingAvatar(emoji: store.settings.avatarEmoji, color: store.settings.avatarColor, moving: world.isMoving, facingLeft: world.facingLeft, reduceMotion: store.settings.reduceMotion)
                    .position(x: world.position.x * geo.size.width, y: world.position.y * geo.size.height)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                hud(course, near: near)
            }
            .onAppear {
                world.size = geo.size
                if let p = store.progress[course.id]?.avatarPosition { world.position = CGPoint(x: p.x, y: p.y) }
                focused = true
                if voiceOver { showList = true }
                if ProcessInfo.processInfo.arguments.contains("-openChapter"), let ch = course.chapters.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { activeChapter = ChapterRef(id: ch.id) }
                }
            }
            .onChange(of: geo.size) { _, s in world.size = s }
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onKeyPress(phases: [.down, .up]) { press in
            let map: [String: String] = ["w": "up", "s": "down", "a": "left", "d": "right"]
            var dir: String?
            switch press.key {
            case .upArrow: dir = "up"; case .downArrow: dir = "down"; case .leftArrow: dir = "left"; case .rightArrow: dir = "right"
            case .return, .space:
                if press.phase == .down, let near { enter(near, course) }
                return .handled
            default: dir = map[press.characters.lowercased()]
            }
            guard let dir else { return .ignored }
            if press.phase == .down { world.keys.insert(dir) } else { world.keys.remove(dir) }
            return .handled
        }
        .task {
            while !Task.isCancelled {
                let covered = activeChapter != nil || sheet != nil || showList
                let idle = world.target == nil && world.joystick == .zero && world.keys.isEmpty
                if !covered { world.tick() }
                // Sleep longer when nothing is moving so the app can rest (battery, and UI-test idling).
                try? await Task.sleep(nanoseconds: covered || idle ? 120_000_000 : 16_000_000)
            }
        }
        .onDisappear {
            store.progress[course.id]?.avatarPosition = CodablePoint(x: world.position.x, y: world.position.y)
            store.save()
        }
        .fullScreenCover(item: $activeChapter, onDismiss: { checkUnlocks(course) }) { ref in
            ChapterExperienceView(courseID: course.id, chapterID: ref.id)
                .environment(store)
        }
        .sheet(item: $sheet) { s in
            switch s {
            case .library: LibraryView(course: course).pageSheet()
            case .pond: ReflectionPondView(course: course).pageSheet()
            case .campfire: ReviewCampfireView(course: course).pageSheet()
            case .settings: SettingsView().pageSheet()
            }
        }
        .sheet(isPresented: $showList) { QuickTravelList(course: course, points: points, status: { status(of: $0, course) }) { poi in showList = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { enter(poi, course) } } }
        .toast($toast)
    }

    @State private var statusSnapshot: [UUID: ChapterStatus] = [:]

    private func checkUnlocks(_ course: Course) {
        guard let course = store.course(course.id) else { return }
        for ch in course.chapters {
            let st = store.chapterProgress(course, ch).status
            if st == .unlocked && statusSnapshot[ch.id] == .locked {
                celebrate = ch.id
                toast = "🔓 \(ch.locationName) unlocked!"
                world.target = CGPoint(x: Self.chapterSpots[min(ch.index, 4)].x, y: Self.chapterSpots[min(ch.index, 4)].y + 0.07)
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) { celebrate = nil }
            }
        }
    }

    private func status(of poi: PointOfInterest, _ course: Course) -> ChapterStatus? {
        if case .chapter(let id) = poi.kind, let ch = course.chapters.first(where: { $0.id == id }) { return store.chapterProgress(course, ch).status }
        return nil
    }

    private func npc(of poi: PointOfInterest, _ course: Course) -> NPC? {
        if case .chapter(let id) = poi.kind { return course.chapters.first { $0.id == id }?.npc }
        return nil
    }

    private func enter(_ poi: PointOfInterest, _ course: Course) {
        switch poi.kind {
        case .chapter(let id):
            guard let ch = course.chapters.first(where: { $0.id == id }) else { return }
            if store.chapterProgress(course, ch).status == .locked {
                toast = "🔒 Master Chapter \(ch.index) to unlock \(ch.locationName)"
                return
            }
            if store.settings.requireApproval && course.reviewStatus != .approved {
                toast = "⏳ Your educator has not approved this book yet"
                return
            }
            statusSnapshot = Dictionary(uniqueKeysWithValues: course.chapters.map { ($0.id, store.chapterProgress(course, $0).status) })
            activeChapter = ChapterRef(id: id)
        case .library: sheet = .library
        case .pond: sheet = .pond
        case .campfire: sheet = .campfire
        }
    }

    // MARK: HUD

    private func hud(_ course: Course, near: PointOfInterest?) -> some View {
        VStack {
            HStack(spacing: 14) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.mTitle2).frame(width: 52, height: 52).background(Circle().fill(Palette.surface)).overlay(Circle().strokeBorder(Palette.ink.opacity(0.35)))
                }
                .accessibilityLabel("Back to home")
                VStack(alignment: .leading, spacing: 2) {
                    Text(course.topic).font(.display(20, .semibold))
                    HStack(spacing: 6) {
                        ForEach(course.chapters) { ch in
                            let st = store.chapterProgress(course, ch).status
                            Capsule().fill(st == .mastered ? Palette.forest : st == .locked ? Palette.rule : Palette.ochre).frame(width: 34, height: 6)
                        }
                        Text("\(store.progress[course.id]?.xp ?? 0) XP").font(.ui(12, .bold)).foregroundStyle(Palette.ochre)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.ink.opacity(0.35)))
                .accessibilityElement(children: .combine)
                Spacer()
                hudButton("list.bullet", "Quick travel list") { showList = true }
                hudButton("books.vertical.fill", "Library: private help") { sheet = .library }
                hudButton("flame.fill", "Review campfire") { sheet = .campfire }
                hudButton("gearshape.fill", "Settings") { sheet = .settings }
            }
            .padding(.horizontal, 24).padding(.top, 28)
            Spacer()
            HStack(alignment: .bottom) {
                Joystick(vector: Binding(get: { world.joystick }, set: { world.joystick = $0 }))
                    .padding(28)
                Spacer()
                if let near { proximityCard(near, course).transition(.move(edge: .bottom).combined(with: .opacity)) }
                Spacer()
                Color.clear.frame(width: 160, height: 1)
            }
            .animation(.spring, value: near?.id)
        }
    }

    private func hudButton(_ icon: String, _ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.ui(19, .medium)).frame(width: 52, height: 52).background(Circle().fill(Palette.surface)).overlay(Circle().strokeBorder(Palette.ink.opacity(0.35)))
        }
        .accessibilityLabel(label)
    }

    private func proximityCard(_ poi: PointOfInterest, _ course: Course) -> some View {
        let st = status(of: poi, course)
        let locked = st == .locked
        let npc = npc(of: poi, course)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(npc?.emoji ?? "✨").font(.system(size: 40))
                VStack(alignment: .leading) {
                    Text(poi.title).font(.mTitle3)
                    Text(poi.subtitle).font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                }
            }
            if let npc, !locked {
                Text("“\(npc.greeting)”").font(.custom(Typeface.serifItalic, size: 15)).fixedSize(horizontal: false, vertical: true)
            }
            Button { enter(poi, course) } label: {
                Label(locked ? "Locked" : st == .mastered ? "Revisit" : "Enter", systemImage: locked ? "lock.fill" : "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary(locked ? Palette.inkMuted : Palette.forest))
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(20)
        .frame(width: 420)
        .background(RoundedRectangle(cornerRadius: 18).fill(Palette.surface)).overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Palette.ink.opacity(0.4)))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .padding(.bottom, 30)
    }
}

// MARK: - Pieces

struct LocationMarker: View {
    var poi: PointOfInterest
    var status: ChapterStatus?
    var npc: NPC?
    var isNear: Bool
    var celebrating: Bool
    var still: Bool = false
    @State private var bob = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if status == .unlocked || status == .inProgress || celebrating {
                    Circle().strokeBorder(poi.color.opacity(0.5), lineWidth: 2).frame(width: 124, height: 124).scaleEffect(bob ? 1.12 : 0.96).opacity(bob ? 0.2 : 0.9)
                }
                Building(symbol: poi.symbol, color: poi.color, locked: status == .locked, number: poi.number)
                if status == .mastered {
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 30)).foregroundStyle(Palette.onAccent, Palette.forest).offset(x: 38, y: -36)
                }
                if let npc, status != .locked {
                    Text(npc.emoji).font(.system(size: 26))
                        .frame(width: 46, height: 46).background(Circle().fill(Palette.surface)).overlay(Circle().strokeBorder(Palette.ink.opacity(0.6), lineWidth: 1.2))
                        .offset(x: -50, y: 30 + (bob ? -3 : 1))
                }
                if celebrating { ConfettiView().frame(width: 220, height: 220).allowsHitTesting(false) }
            }
            Text(poi.title)
                .font(.displayItalic(17))
                .padding(.horizontal, 14).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 4).fill(Palette.surface))
                .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Palette.ink.opacity(isNear ? 0.9 : 0.5), lineWidth: isNear ? 1.6 : 1))
                .foregroundStyle(Palette.ink)
                .scaleEffect(isNear ? 1.08 : 1)
        }
        .animation(.easeInOut(duration: 1.6).repeatForever(), value: bob)
        .onAppear { bob = !still }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(poi.title). \(poi.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

struct Building: View {
    var symbol: String
    var color: Color
    var locked: Bool
    var number: Int? = nil
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.14)).frame(width: 92, height: 20).offset(y: 46)
            Circle().fill(Palette.surface).frame(width: 92, height: 92)
            Circle().strokeBorder(Palette.ink.opacity(0.85), lineWidth: 1.6).frame(width: 92, height: 92)
            Circle().strokeBorder(locked ? Palette.inkMuted.opacity(0.4) : color, lineWidth: 6).frame(width: 78, height: 78)
            Circle().strokeBorder(Palette.ink.opacity(0.5), lineWidth: 0.8).frame(width: 64, height: 64)
            if let number {
                VStack(spacing: -2) {
                    Text("\(number)").font(.display(30, .semibold))
                    Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(locked ? Palette.inkMuted : Palette.ink)
            } else {
                Image(systemName: symbol).font(.system(size: 26, weight: .medium)).foregroundStyle(locked ? Palette.inkMuted : color)
            }
            if locked {
                Image(systemName: "lock.fill").font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.onAccent)
                    .frame(width: 30, height: 30).background(Circle().fill(Palette.ink)).offset(x: 32, y: -32)
            }
        }
    }
}

struct WalkingAvatar: View {
    @Environment(ClassroomStore.self) private var classroom
    var emoji: String
    var color: Int
    var moving: Bool
    var facingLeft: Bool
    var reduceMotion: Bool
    var body: some View {
        TimelineView(.animation(paused: !moving || reduceMotion)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let bounce = moving && !reduceMotion ? abs(sin(t * 10)) * 8 : 0
            VStack(spacing: 0) {
                Group {
                    if let s = classroom.currentStudent { PersonAvatar(asset: s.avatar, name: s.name, size: 64) }
                    else { AvatarView(emoji: emoji, colorIndex: color, size: 62) }
                }
                .shadow(color: .black.opacity(0.2), radius: 4, y: 3)
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                    .offset(y: -bounce)
                Ellipse().fill(.black.opacity(0.25)).frame(width: 46 - bounce, height: 12).offset(y: -4)
            }
        }
    }
}

struct Joystick: View {
    @Binding var vector: CGVector
    @State private var knob: CGSize = .zero
    private let radius: CGFloat = 64
    var body: some View {
        ZStack {
            Circle().fill(Palette.surface.opacity(0.7)).frame(width: radius * 2, height: radius * 2)
                .overlay(Circle().strokeBorder(Palette.ink.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [3, 4])))
            Circle().fill(Palette.surface).frame(width: 58, height: 58).overlay(Circle().strokeBorder(Palette.ink.opacity(0.7), lineWidth: 1.4)).shadow(color: .black.opacity(0.15), radius: 4, y: 2).offset(knob)
        }
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged { v in
                var d = v.translation
                let len = sqrt(d.width * d.width + d.height * d.height)
                if len > radius { d = CGSize(width: d.width / len * radius, height: d.height / len * radius) }
                knob = d
                vector = CGVector(dx: d.width / radius, dy: d.height / radius)
            }
            .onEnded { _ in withAnimation(.spring) { knob = .zero }; vector = .zero })
        .accessibilityLabel("Movement joystick. Use Quick travel list instead with VoiceOver.")
    }
}

struct QuickTravelList: View {
    var course: Course
    var points: [PointOfInterest]
    var status: (PointOfInterest) -> ChapterStatus?
    var go: (PointOfInterest) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List(points) { p in
                Button { go(p) } label: {
                    HStack(spacing: 16) {
                        Image(systemName: status(p) == .locked ? "lock.fill" : p.symbol).font(.mTitle2).foregroundStyle(.white)
                            .frame(width: 50, height: 50).background(RoundedRectangle(cornerRadius: 12).fill(p.color.gradient))
                        VStack(alignment: .leading) {
                            Text(p.title).font(.mHeadline)
                            Text(p.subtitle).font(.mSubheadline).foregroundStyle(Palette.inkSoft)
                        }
                        Spacer()
                        if status(p) == .mastered { Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.mint) }
                    }
                }
                .disabled(status(p) == .locked)
            }
            .navigationTitle("Quick travel")
            .toolbar { Button("Close") { dismiss() } }
        }
    }
}

struct ConfettiView: View {
    @State private var go = false
    var body: some View {
        ZStack {
            ForEach(0..<24, id: \.self) { i in
                let angle = Double(i) / 24 * 2 * .pi
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.avatarColors[i % Theme.avatarColors.count])
                    .frame(width: 8, height: 14)
                    .rotationEffect(.degrees(go ? Double(i * 40) : 0))
                    .offset(x: go ? cos(angle) * 110 : 0, y: go ? sin(angle) * 110 + 30 : 0)
                    .opacity(go ? 0 : 1)
            }
        }
        .onAppear { withAnimation(.easeOut(duration: 1.8)) { go = true } }
    }
}
