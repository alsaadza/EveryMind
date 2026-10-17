import SwiftUI

@main
struct EducateAIApp: App {
    @State private var store = AppStore()
    @State private var classroom = ClassroomStore()

    init() { Self.applyAppearance() }

    /// UIKit-backed chrome (navigation titles, segmented controls) uses the same typefaces as the rest of Margin.
    static func applyAppearance() {
        let ink = UIColor(Palette.ink)
        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        if let large = UIFont(name: Typeface.display, size: 34) {
            nav.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: large), .foregroundColor: ink]
        }
        if let title = UIFont(name: Typeface.uiSemibold, size: 17) {
            nav.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: title), .foregroundColor: ink]
        }
        if let button = UIFont(name: Typeface.uiSemibold, size: 16) {
            let b = UIBarButtonItemAppearance()
            b.normal.titleTextAttributes = [.font: button]
            nav.buttonAppearance = b
            nav.doneButtonAppearance = b
        }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        if let seg = UIFont(name: Typeface.uiMedium, size: 14), let segBold = UIFont(name: Typeface.uiSemibold, size: 14) {
            UISegmentedControl.appearance().setTitleTextAttributes([.font: seg], for: .normal)
            UISegmentedControl.appearance().setTitleTextAttributes([.font: segBold], for: .selected)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(classroom)
                .tint(Palette.forest)
                .font(.mBody)
                .foregroundStyle(Palette.ink)
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(ClassroomStore.self) private var classroom
    var body: some View {
        Group {
            switch classroom.role {
            case .none: WelcomeView()
            case .teacher: TeacherShell()
            case .student:
                if let s = classroom.currentStudent { StudentShell(student: s).id(s.id) } else { StudentSignInView() }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: classroom.role)
        .animation(.easeInOut(duration: 0.35), value: classroom.currentStudentID)
        .transaction { if store.settings.reduceMotion { $0.animation = nil } }
        .onChange(of: classroom.currentStudentID, initial: true) { _, _ in
            // The quest engine uses the signed-in student's first name.
            if let s = classroom.currentStudent {
                store.settings.learnerName = s.firstName
                store.settings.onboarded = true
            }
        }
    }
}
