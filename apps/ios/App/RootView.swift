import SwiftUI
import MuralCore

struct RootView: View {
    @State private var coordinator: ConversationCoordinator
    @State private var tab = 0
    @State private var onboarding = false
    @Environment(\.scenePhase) private var scenePhase
    init(store: LearningStore) {
        let coordinator = ConversationCoordinator(store: store)
        #if DEBUG && targetEnvironment(simulator)
        _tab = State(initialValue: ScreenshotPreview.tab)
        #endif
        _coordinator = State(initialValue: coordinator)
    }
    var body: some View {
        @Bindable var coordinator = coordinator
        TabView(selection: $tab) {
            Tab("Talk", systemImage: "waveform", value: 0) { shell { TalkView(coordinator: coordinator) } }
            Tab("Themes", systemImage: "square.grid.2x2", value: 1) {
                shell { ThemesView(coordinator: coordinator) { theme in coordinator.chooseTheme(theme); tab = 0 } }
            }
            Tab("Words", systemImage: "book", value: 2) { shell { WordsView(coordinator: coordinator) } }
        }
        .tint(MuralColor.ink)
        .sheet(isPresented: $coordinator.showSettings, onDismiss: { Task { await coordinator.refreshContinuation() } }) {
            SettingsView(coordinator: coordinator)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $coordinator.showAIConsent, onDismiss: { coordinator.resumeAfterAIConsent() }) {
            AIConsentView(agree: { coordinator.acceptAIConsent() }, decline: { coordinator.declineAIConsent() })
        }
        .fullScreenCover(isPresented: $onboarding) { OnboardingView(coordinator: coordinator) { coordinator.store.updatePreferences { $0.hasOnboarded = true }; onboarding = false } }
        .alert("A little interruption", isPresented: Binding(get: { coordinator.error != nil || coordinator.store.error != nil }, set: { if !$0 { coordinator.error = nil; coordinator.store.error = nil; coordinator.hostedAccessFailure = nil } })) {
            if coordinator.personalKeyFailure != nil {
                Button("Review in Advanced") {
                    coordinator.error = nil; coordinator.store.error = nil
                    coordinator.requestAdvancedFocus = true; coordinator.showSettings = true
                }
            }
            if let hostedFailure = coordinator.hostedAccessFailure {
                if case .noMinutes = hostedFailure {
                    Button("Check minutes") {
                        coordinator.error = nil; coordinator.store.error = nil; coordinator.hostedAccessFailure = nil
                        coordinator.requestAccountFocus = true; coordinator.showSettings = true
                    }
                }
                if hostedFailure.needsSignInRecovery {
                    Button("Sign in") {
                        coordinator.error = nil; coordinator.store.error = nil; coordinator.hostedAccessFailure = nil
                        coordinator.requestAccountFocus = true; coordinator.showSettings = true
                    }
                }
                Button("Use my API key") {
                    coordinator.error = nil; coordinator.store.error = nil; coordinator.hostedAccessFailure = nil
                    coordinator.requestAdvancedFocus = true; coordinator.showSettings = true
                }
            }
            Button("OK", role: .cancel) { coordinator.error = nil; coordinator.store.error = nil; coordinator.hostedAccessFailure = nil }
        } message: { Text(coordinator.error ?? coordinator.store.error ?? "") }
        .task { coordinator.resume(); AppleMinutePurchases.shared.start(); await HostedCloseRecovery.shared.resume() }
        .onChange(of: HostedCloseRecovery.shared.revision) { _, _ in Task { await coordinator.refreshContinuation() } }
        .onChange(of: AppleMinutePurchases.shared.balanceRevision) { _, _ in Task { await coordinator.refreshContinuation() } }
        .onAppear {
            let arguments = ProcessInfo.processInfo.arguments
            #if DEBUG && targetEnvironment(simulator)
            if arguments.contains("--preview") && arguments.contains("--preview-onboarding") {
                onboarding = !coordinator.store.preferences.hasOnboarded
                return
            }
            #endif
            onboarding = !coordinator.store.preferences.hasOnboarded && !arguments.contains("--preview") && !AudioVerification.requested
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { coordinator.background(); HostedCloseRecovery.shared.pause() }
            else if phase == .active { coordinator.resume(); Task { await HostedCloseRecovery.shared.resume(); await AppleMinutePurchases.shared.checkPurchases() } }
        }
        #if DEBUG
        .task { await prepareDebugSession() }
        #endif
    }
    #if DEBUG
    private func prepareDebugSession() async {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--preview-onboarding") {
            coordinator.store.updatePreferences { $0.hasOnboarded = false }
        }
        if ProcessInfo.processInfo.arguments.contains("--preview"), ProcessInfo.processInfo.arguments.contains("--preview-existing-user") {
            coordinator.store.updatePreferences { $0.hasOnboarded = true }
        }
        if let screen = ScreenshotPreview.screen { coordinator.prepareScreenshot(screen) }
        coordinator.prepareTypedReplyPreview()
        coordinator.prepareConversationPolicyPreview()
        coordinator.prepareCaptionFollowingPreview()
        if ProcessInfo.processInfo.arguments.contains("--verify-network-recovery") {
            coordinator.notice = await LiveTransport.verifyRecoveryLifecycle() ? "Network recovery lifecycle passed" : "Network recovery lifecycle failed"
            return
        }
        #endif
        if AudioVerification.requested { await AudioVerification.run(coordinator) }
        else if ProcessInfo.processInfo.arguments.contains("--ended-conversation") { coordinator.prepareConversationPreview(active: false) }
        else if ProcessInfo.processInfo.arguments.contains("--active-conversation") { coordinator.prepareConversationPreview(active: true) }
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--preview-caption-following") { await coordinator.runCaptionFollowingPreview() }
        #endif
    }
    #endif
    private func shell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content().background(MuralColor.cream).toolbar {
                ToolbarItem(placement: .topBarLeading) { Brand().fixedSize() }.sharedBackgroundVisibility(.hidden)
                ToolbarItem(placement: .topBarTrailing) {
                    Button { coordinator.showSettings = true } label: { Image(systemName: "slider.horizontal.3") }
                        .accessibilityLabel("Settings")
                }
            }.toolbarBackground(MuralColor.cream, for: .navigationBar)
        }
    }
}

struct TalkView: View {
    @Bindable var coordinator: ConversationCoordinator
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var typing = false
    @State private var conversationChoice = false
    @State private var openAccountAfterContinuation = false
    @State private var resumeAfterChoice = false
    @State private var pinyinExpanded = true
    @State private var transcript: SessionRecord?
    @State private var lookup: WordLookup?
    init(coordinator: ConversationCoordinator) {
        self.coordinator = coordinator
        #if DEBUG && targetEnvironment(simulator)
        if ScreenshotPreview.screen == .meaning {
            _lookup = State(initialValue: WordLookup(word: "sobremesa", sentence: "Podemos quedarnos de sobremesa y charlar un rato."))
        }
        #endif
    }
    var body: some View {
        GeometryReader { geometry in
            let scrollPage = typeSize.isAccessibilitySize || geometry.size.height < 480
            let compact = !scrollPage && geometry.size.height < 620
            if scrollPage {
                ScrollView {
                    talkContent(scrollPage: true, compact: compact)
                        .frame(minHeight: geometry.size.height)
                }.scrollIndicators(.hidden)
            } else {
                talkContent(scrollPage: false, compact: compact)
                    .frame(height: geometry.size.height)
            }
        }
        .sheet(isPresented: $typing) { TypedReplyView(coordinator: coordinator) }
        .onChange(of: coordinator.hasContinuation, initial: true) { _, waiting in
            if waiting && !coordinator.isRunning { conversationChoice = true }
        }
        .onChange(of: coordinator.isPaused, initial: true) { _, paused in
            if paused && coordinator.error == nil { conversationChoice = true }
        }
        .sheet(isPresented: $conversationChoice, onDismiss: {
            if openAccountAfterContinuation {
                openAccountAfterContinuation = false
                coordinator.requestAccountFocus = true; coordinator.showSettings = true
            } else if resumeAfterChoice {
                resumeAfterChoice = false
                coordinator.start()
            }
        }) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(coordinator.isPaused
                             ? (coordinator.pauseClosureConfirmed
                                ? "Your conversation is saved on this phone. Voice billing has stopped. Resume when you’re ready, or start a new conversation."
                                : "Your conversation is saved and the connection is closed. Final voice usage is unconfirmed. You can resume when you’re ready.")
                             : coordinator.notice ?? "Your conversation is saved. You can continue when your minutes finish updating.")
                            .font(.body).foregroundStyle(MuralColor.secondary)
                        Button {
                            if coordinator.continuationNeedsMinutes { openAccountAfterContinuation = true; conversationChoice = false }
                            else { resumeAfterChoice = true; conversationChoice = false }
                        } label: {
                            Text(coordinator.isPaused ? "Resume conversation" : coordinator.continuationNeedsMinutes ? "Add minutes" : "Continue conversation").frame(maxWidth: .infinity, minHeight: 52)
                        }
                        .buttonStyle(.borderedProminent).tint(MuralColor.orange).foregroundStyle(MuralColor.ink)
                        .disabled(!coordinator.isPaused && !coordinator.continuationReady && !coordinator.continuationNeedsMinutes)
                        .accessibilityIdentifier(coordinator.isPaused ? "resume-conversation" : coordinator.continuationNeedsMinutes ? "continuation-add-minutes" : "continue-conversation")
                        Button("New conversation") { conversationChoice = false; coordinator.resetConversation() }
                            .frame(maxWidth: .infinity, minHeight: 44).accessibilityIdentifier("new-conversation")
                    }.padding(24)
                }.background(MuralColor.cream)
                    .navigationTitle(coordinator.isPaused ? "Conversation paused" : "Continue practicing").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { conversationChoice = false } } }
            }
            .tint(MuralColor.ink).presentationDetents(typeSize.isAccessibilitySize ? [.large] : [.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.35), value: coordinator.state)
        .sheet(item: $transcript) { session in
            TranscriptView(session: session, meaningLanguage: coordinator.store.preferences.meaningLanguage)
        }
        .sheet(item: $lookup) { item in LookupView(item: item, coordinator: coordinator) }
    }
    private func talkContent(scrollPage: Bool, compact: Bool) -> some View {
        return VStack(spacing: 0) {
            Text(coordinator.selectedTheme?.title ?? coordinator.language.talkTitle)
                .font(.system(.caption, design: .rounded, weight: .medium)).foregroundStyle(MuralColor.secondary)
                .padding(.horizontal, 14).padding(.vertical, compact ? 6 : 9)
                .background(MuralColor.butter.opacity(0.58), in: Capsule()).padding(.top, 12)
            Spacer(minLength: compact ? 4 : 8)
            if scrollPage {
                conversationContent(orbSide: 112, compact: true, scrollCaptions: false)
            } else {
                // Fit the actual wrapped source, meaning and optional pinyin, not a character count.
                ViewThatFits(in: .vertical) {
                    conversationContent(orbSide: compact ? 150 : 220, compact: compact, scrollCaptions: false)
                    conversationContent(orbSide: compact ? 124 : 156, compact: true, scrollCaptions: false)
                    conversationContent(orbSide: 112, compact: true, scrollCaptions: false)
                    conversationContent(orbSide: 92, compact: true, scrollCaptions: true)
                }.frame(maxHeight: .infinity)
            }
            controls.padding(.top, compact ? 8 : 12).fixedSize(horizontal: false, vertical: true)
            Group {
                let actionLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 12)) : AnyLayout(HStackLayout(spacing: 24))
                actionLayout {
                    if coordinator.state == .active {
                        if coordinator.conversationProvider == .personalKey {
                            Button(coordinator.isMuted ? "Unmute" : "Mute", systemImage: coordinator.isMuted ? "mic.slash.fill" : "mic") {
                                coordinator.toggleMute()
                            }
                            .frame(minHeight: 44)
                            .accessibilityLabel(coordinator.isMuted ? "Unmute microphone" : "Mute microphone")
                            .accessibilityHint("The call stays connected and voice billing continues")
                            .accessibilityIdentifier("mute-conversation")
                        }
                        Button("Type instead", systemImage: "keyboard") { typing = true }
                        Button("A little help", systemImage: "sparkles") { coordinator.help() }
                    } else if coordinator.conversationProvider == .personalKey && !coordinator.isRunning {
                        OpenAIBalanceLink().foregroundStyle(MuralColor.secondary)
                    }
                }.font(.caption)
            }.frame(minHeight: compact ? 28 : 42).fixedSize(horizontal: false, vertical: true)
                .accessibilityHidden(coordinator.state != .active && coordinator.session == nil && coordinator.conversationProvider != .personalKey)
        }.padding(.horizontal, 30).frame(maxWidth: .infinity)
    }
    private func conversationContent(orbSide: CGFloat, compact: Bool, scrollCaptions: Bool) -> some View {
        VStack(spacing: 0) {
            MuralOrb(energy: max(coordinator.outputLevel, coordinator.inputLevel * 0.45), listening: coordinator.state == .active && !coordinator.isMuted, active: coordinator.state != .closing)
                .frame(width: orbSide, height: orbSide).accessibilityIdentifier("talk-orb")
                .padding(.vertical, compact ? 2 : 8)
            VStack(spacing: 2) {
                if coordinator.state == .active, let seconds = coordinator.inactivitySeconds {
                    Text("Ending in \(seconds)s").fontWeight(.medium).monospacedDigit()
                    Text("Reply to continue").font(.system(.caption2, design: .rounded))
                } else { Text(coordinator.status) }
            }
            .font(.system(.caption, design: .rounded)).foregroundStyle(MuralColor.secondary)
            .multilineTextAlignment(.center).frame(minHeight: 36)
            .padding(.top, 6).padding(.bottom, compact ? 8 : 16)
            .accessibilityElement(children: .ignore).accessibilityLabel(coordinator.status)
            .accessibilityAddTraits([.isStaticText, .updatesFrequently]).accessibilityIdentifier("conversation-status")
            if coordinator.estimatedVoiceCostUSD != nil {
                CallCostIndicator(coordinator: coordinator).padding(.bottom, compact ? 4 : 8)
            }
            if scrollCaptions {
                followingPassage { captionArea }
                    .id(coordinator.assistantPassage?.id)
                    .accessibilityIdentifier("conversation-passage-scroll")
            } else { captionArea.frame(maxHeight: .infinity) }
        }
    }
    private var captionArea: some View {
        VStack(spacing: 12) {
            VStack(spacing: coordinator.assistantPassage == nil ? 14 : 12) {
                targetPassage
                if coordinator.store.preferences.meaningVisible { meaningPassage }
            }
            if let user = coordinator.userPassage {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("YOU").font(.system(.caption2, design: .rounded, weight: .medium))
                    Text(user.text).font(.caption).accessibilityIdentifier("user-caption")
                }.foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center).padding(.top, 3)
            }
            if coordinator.working { ProgressView("Checking that for you…").font(.caption).tint(MuralColor.secondary) }
            if let sources = coordinator.session?.topics.last?.sources, !sources.isEmpty {
                Button("Sources", systemImage: "link") { transcript = coordinator.session }.font(.caption)
            }
            if coordinator.conversationProvider == .personalKey && coordinator.personalKeyFailure != nil && !coordinator.isRunning {
                Button("Review API issue in Advanced") {
                    coordinator.requestAdvancedFocus = true; coordinator.showSettings = true
                }.font(.footnote).accessibilityIdentifier("talk-open-advanced")
            }
            if let notice = coordinator.notice, !coordinator.hasContinuation {
                Text(notice).font(.footnote).foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center)
            }
        }.fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: typeSize.isAccessibilitySize ? 100 : 105).frame(maxWidth: .infinity)
    }
    private var targetPassage: some View {
        VStack(spacing: 8) {
            Text(linkedCaption).font(.system(coordinator.assistantPassage == nil ? .largeTitle : .title2, design: .rounded, weight: .medium))
                .tracking(-0.5).multilineTextAlignment(.center).tint(MuralColor.ink)
                .environment(\.openURL, OpenURLAction { url in
                    guard url.scheme == "mural-word", let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let word = components.queryItems?.first?.value else { return .discarded }
                    lookup = WordLookup(word: word, sentence: coordinator.caption); return .handled
                }).accessibilityIdentifier("target-caption")
            if coordinator.language.id == "zh" { PinyinHelp(text: coordinator.caption, expanded: $pinyinExpanded) }
        }.frame(maxWidth: .infinity)
    }
    private var meaningPassage: some View {
        VStack(spacing: 6) {
            Text(coordinator.assistantPassage == nil ? MeaningLanguages.greeting(in: coordinator.store.preferences.meaningLanguage) : !coordinator.meaning.isEmpty ? coordinator.meaning : coordinator.translating ? "Finding the meaning…" : "")
                .font(.subheadline).foregroundStyle(MuralColor.secondary).multilineTextAlignment(.center)
                .accessibilityIdentifier("meaning-caption")
            if let error = coordinator.meaningError {
                Text(error).foregroundStyle(MuralColor.secondary).accessibilityIdentifier("meaning-error")
                if coordinator.canRetryMeaning {
                    Button("Try meaning again") { coordinator.retryMeaning() }
                }
            }
        }.font(.footnote).frame(maxWidth: .infinity)
    }
    private func followingPassage<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        FollowingPassage(passageID: coordinator.session.map { $0.id.uuidString + ":" + (coordinator.assistantPassage?.id ?? "") },
                         content: content, following: $coordinator.targetCaptionFollowing)
    }
    private var linkedCaption: AttributedString {
        var result = AttributedString()
        for segment in CaptionWords.segments(coordinator.caption, languageID: coordinator.language.id) {
            var part = AttributedString(segment.text)
            if coordinator.assistantPassage != nil, let word = segment.lookup {
                var components = URLComponents(); components.scheme = "mural-word"; components.host = "lookup"
                components.queryItems = [URLQueryItem(name: "word", value: word)]
                part.link = components.url
            }
            part.foregroundColor = MuralColor.ink; result.append(part)
        }
        return result
    }
    private var controls: some View {
        let outerLayout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 20)) : AnyLayout(HStackLayout(alignment: .center, spacing: 27))
        let labelLayout = typeSize.isAccessibilitySize ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(VStackLayout(spacing: 6))
        return outerLayout {
            Button { coordinator.toggleMeaning() } label: {
                labelLayout {
                    Image(systemName: coordinator.store.preferences.meaningVisible ? "captions.bubble.fill" : "captions.bubble")
                        .font(.system(size: 20)).frame(width: 48, height: 48).modifier(SoftGlass(tint: coordinator.store.preferences.meaningVisible ? MuralColor.butter.opacity(0.7) : .white.opacity(0.4)))
                    Text("Meaning").font(.caption2)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityLabel(coordinator.store.preferences.meaningVisible ? "Hide meaning subtitles" : "Show meaning subtitles")
                .accessibilityValue(coordinator.store.preferences.meaningVisible ? "On" : "Off")
            Button {
                if coordinator.canPause { coordinator.pauseConversation() }
                else if coordinator.state == .active { coordinator.toggleMute() }
                else if coordinator.hasContinuation || coordinator.isPaused { conversationChoice = true }
                else if !coordinator.isRunning { coordinator.start() }
            } label: {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(red: 1, green: 0.73, blue: 0.48), MuralColor.orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    if coordinator.state == .connecting || coordinator.state == .closing { ProgressView().tint(MuralColor.ink) }
                    else { Image(systemName: coordinator.isPaused ? "play.fill" : coordinator.canPause ? "pause.fill" : coordinator.isMuted && coordinator.state == .active ? "mic.slash" : "mic").font(.system(size: 28, weight: .regular)).contentTransition(.symbolEffect(.replace)) }
                }.frame(width: 76, height: 76).shadow(color: MuralColor.orange.opacity(0.25), radius: 10, y: 6)
            }.buttonStyle(.plain).padding(.bottom, typeSize.isAccessibilitySize ? 0 : 18)
                .disabled(coordinator.state == .connecting || coordinator.state == .closing)
                .accessibilityLabel(coordinator.isPaused ? "Resume conversation" : coordinator.canPause ? "Pause conversation" : coordinator.state == .active ? (coordinator.isMuted ? "Unmute microphone" : "Mute microphone") : "Start conversation")
                .accessibilityHint(coordinator.canPause ? "Closes the voice connection and saves this conversation for later" : "")
                .accessibilityIdentifier("start-conversation")
            Button { if coordinator.isRunning { coordinator.end() } else { transcript = coordinator.session } } label: {
                labelLayout {
                    Image(systemName: coordinator.isRunning ? "phone.down" : "text.bubble").font(.system(size: 20)).frame(width: 48, height: 48).modifier(SoftGlass())
                    Text(coordinator.isRunning ? "End" : "Transcript").font(.caption2)
                }.contentShape(Rectangle())
            }.buttonStyle(.plain).accessibilityLabel(coordinator.isRunning ? "End conversation" : "Conversation transcript")
                .disabled(coordinator.session == nil)
        }.foregroundStyle(MuralColor.ink)
    }
}

struct WordLookup: Identifiable { var id = UUID(); var word: String; var sentence: String }
struct LookupView: View {
    let item: WordLookup
    let coordinator: ConversationCoordinator
    @State private var explanation: String?
    @State private var error: String?
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(item.word).font(.system(.largeTitle, design: .rounded, weight: .medium))
                if coordinator.language.id == "zh" { PinyinHelp(text: item.word) }
                Text(item.sentence).font(.title3).foregroundStyle(MuralColor.secondary)
                if let explanation { Text(explanation).font(.body).textSelection(.enabled) }
                else if let error { Text(error).foregroundStyle(MuralColor.secondary) }
                else { ProgressView("Finding the meaning…") }
                Spacer()
            }.padding(28).frame(maxWidth: .infinity, alignment: .leading).background(MuralColor.cream)
                .navigationTitle("A little meaning").navigationBarTitleDisplayMode(.inline)
        }.presentationDetents([.medium, .large])
            .task {
                #if DEBUG && targetEnvironment(simulator)
                if ScreenshotPreview.screen == .meaning {
                    explanation = "The relaxed conversation that continues after a meal, when nobody is in a hurry to leave."
                    return
                }
                #endif
                do { explanation = try await coordinator.lookup(word: item.word, sentence: item.sentence) }
                catch { self.error = error.localizedDescription }
            }
    }
}

struct TypedReplyView: View {
    let coordinator: ConversationCoordinator
    @State private var text = ""
    @State private var sending = false
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Say it your way.").font(.system(.title, design: .rounded, weight: .semibold)).fixedSize(horizontal: false, vertical: true)
                TextField("Reply in \(coordinator.language.name) or another language", text: $text, axis: .vertical).lineLimit(3...6).focused($focused).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 22)).accessibilityIdentifier("typed-reply-input")
                    .onChange(of: text) { _, _ in coordinator.noteTypingActivity() }
                if let error = coordinator.typedReplyError {
                    Text(error).font(.footnote).foregroundStyle(MuralColor.secondary).fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("typed-reply-error")
                }
                Button { sending = true; Task { let ok = await coordinator.sendTyped(text); sending = false; if ok { dismiss() } } } label: {
                    HStack { Text(sending ? "Sending…" : "Send reply").fixedSize(horizontal: false, vertical: true); Spacer(); Image(systemName: "arrow.up") }.padding(18).background(MuralColor.orange, in: Capsule())
                }.disabled(sending || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("typed-reply-send").id("typed-reply-send")
                Spacer()
            }.padding(26).frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(MuralColor.ink)
            }.accessibilityIdentifier("typed-reply-scroll").background(MuralColor.cream)
                .onChange(of: coordinator.typedReplyError) { _, error in
                    if error != nil { withAnimation { proxy.scrollTo("typed-reply-send", anchor: .bottom) } }
                }
            }
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }.presentationDetents([.medium, .large]).onAppear { coordinator.typedReplyError = nil; coordinator.noteTypingActivity(); focused = true }
    }
}


/// The viewport stays put; the text advances at a reading pace until touched.
private struct FollowingPassage<Content: View>: View {
    let passageID: String?
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Binding var following: CaptionFollowing
    @State private var position = ScrollPosition(y: 0)
    @State private var offset = 0.0
    @State private var maximum = 0.0
    private var followingValue: String {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--preview-caption-following") {
            return "\(Int(offset))|\(following.interrupted ? "paused" : "following")"
        }
        #endif
        return following.interrupted ? "Automatic scrolling paused" : ""
    }
    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                content().frame(maxWidth: .infinity).frame(minHeight: viewport.size.height)
            }
            .scrollPosition($position)
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: Double.self) { geometry in
                max(0, geometry.contentSize.height - geometry.containerSize.height)
            } action: { _, value in maximum = value }
            .onScrollGeometryChange(for: Double.self) { $0.contentOffset.y } action: { _, value in offset = value }
            .onScrollPhaseChange { _, phase in
                if phase == .tracking || phase == .interacting || phase == .decelerating { following.interrupt() }
            }
            .accessibilityValue(followingValue)
            .task(id: passageID) {
                following.receive(passageID)
                position.scrollTo(y: 0)
                guard passageID != nil else { return }
                do {
                    try await Task.sleep(for: .milliseconds(900))
                    while !Task.isCancelled {
                        if !voiceOver && !following.interrupted {
                            let next = following.nextOffset(current: offset, maximum: maximum, elapsed: 0.05, reducedMotion: reduceMotion)
                            if next > offset + 0.01 {
                                if reduceMotion { position.scrollTo(y: next) }
                                else { withAnimation(.linear(duration: 0.05)) { position.scrollTo(y: next) } }
                            }
                        }
                        try await Task.sleep(for: .milliseconds(50))
                    }
                } catch { /* Passage change or view dismissal cancels following. */ }
            }
        }
    }
}
