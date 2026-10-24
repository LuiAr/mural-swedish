import SwiftUI

/// Fixed editorial illustrations, never connected to playback, owner data or a provider.
struct ReleaseFeatureArtwork: View {
    let featureID: String
    private let orange = Color(red: 1, green: 0.43, blue: 0.14)
    private let ink = Color(red: 0.16, green: 0.17, blue: 0.15)
    private let paper = Color(red: 1, green: 0.98, blue: 0.94)
    private var height: CGFloat { featureID == "conversation-recap" ? 320 : 220 }

    var body: some View {
        GeometryReader { geometry in
            artwork.frame(width: 360, height: height)
                .scaleEffect(geometry.size.width / 360, anchor: .topLeading)
        }
        .aspectRatio(360 / height, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityHidden(true)
    }

    @ViewBuilder private var artwork: some View {
        switch featureID {
        case "listening": listening
        case "daily-review": recall
        case "conversation-recap": recap
        case "swedish-forms": forms
        default: updates
        }
    }

    private var listening: some View {
        ZStack {
            LinearGradient(colors: [Color(white: 0.12), .black], startPoint: .topLeading, endPoint: .bottomTrailing)
            Ellipse().fill(orange.opacity(0.28)).frame(width: 260, height: 110).blur(radius: 54).offset(y: 28)
            VStack(spacing: 0) {
                Text("en bok").font(.system(size: 34, weight: .semibold, design: .serif)).foregroundStyle(paper)
                Text("book").font(.system(size: 14)).foregroundStyle(paper.opacity(0.55)).padding(.top, 4)
                waveform.frame(width: 230, height: 42).padding(.top, 14)
                HStack(spacing: 10) {
                    Label("Listen", systemImage: "speaker.wave.2.fill")
                        .foregroundStyle(.black).padding(.horizontal, 17).padding(.vertical, 10)
                        .background(orange, in: Capsule())
                    Label("Slow", systemImage: "tortoise.fill")
                        .foregroundStyle(paper).padding(.horizontal, 17).padding(.vertical, 10)
                        .background(.white.opacity(0.12), in: Capsule())
                }.font(.system(size: 13, weight: .semibold)).padding(.top, 14)
            }
        }
    }

    private var waveform: some View {
        Canvas { context, size in
            let levels: [CGFloat] = [3, 5, 9, 6, 15, 24, 16, 30, 39, 23, 12, 21, 36, 28, 17, 10, 25, 32, 22, 13, 5, 8, 4]
            for (index, level) in levels.enumerated() {
                let x = CGFloat(index) * size.width / CGFloat(levels.count)
                let rect = CGRect(x: x, y: (size.height - level) / 2, width: 3, height: level)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(index < 14 ? orange : .white.opacity(0.3)))
            }
        }
    }

    private var tiles: some View {
        Canvas { context, _ in
            for row in 0..<4 {
                for column in 0..<5 {
                    let rect = CGRect(x: column * 96 - 48, y: row * 96 - 34, width: 84, height: 84)
                    context.fill(Path(roundedRect: rect, cornerRadius: 24), with: .color(.black.opacity(0.065)))
                }
            }
        }.background(Color(white: 0.97))
    }

    private var recall: some View {
        ZStack {
            tiles
            recallCard(word: "book", caption: "THE MEANING", color: paper, revealed: false)
                .rotationEffect(.degrees(-9)).offset(x: -65, y: 7)
            recallCard(word: "en bok", caption: "YOU REMEMBERED", color: Color(red: 0.86, green: 0.90, blue: 0.79), revealed: true)
                .rotationEffect(.degrees(8)).offset(x: 64, y: -1)
        }
    }

    private func recallCard(word: String, caption: String, color: Color, revealed: Bool) -> some View {
        VStack(spacing: 0) {
            Text(caption).font(.system(size: 8, weight: .bold)).tracking(1.2).foregroundStyle(ink.opacity(0.55))
            Spacer()
            Text(word).font(.system(size: 28, weight: .medium, design: .serif)).foregroundStyle(ink)
            Spacer()
            Image(systemName: revealed ? "checkmark.circle.fill" : "arrow.turn.down.right")
                .font(.system(size: 22, weight: .medium)).foregroundStyle(revealed ? Color(red: 0.28, green: 0.42, blue: 0.23) : orange)
        }
        .padding(.vertical, 19).frame(width: 132, height: 174)
        .background(color, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.black.opacity(0.06)))
        .shadow(color: .black.opacity(0.16), radius: 16, x: 0, y: 12)
    }

    private var recap: some View {
        ZStack(alignment: .top) {
            Color.black
            Ellipse().fill(orange.opacity(0.4)).frame(width: 260, height: 70).blur(radius: 40).offset(y: 69)
            Text("One more try,\nin your own words.")
                .font(.system(size: 24, weight: .semibold)).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true).foregroundStyle(.white)
                .frame(width: 320).padding(.top, 24)
            recapPhone.frame(width: 280, height: 280).offset(y: 106)
        }
    }

    private var recapPhone: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 38).fill(LinearGradient(colors: [Color(white: 0.55), Color(white: 0.16)], startPoint: .topLeading, endPoint: .bottomTrailing))
            RoundedRectangle(cornerRadius: 34).fill(paper).padding(4)
            VStack(alignment: .leading, spacing: 13) {
                Capsule().fill(.black).frame(width: 78, height: 19).frame(maxWidth: .infinity).padding(.bottom, 2)
                HStack {
                    Image(systemName: "text.bubble").foregroundStyle(orange)
                    Text("Conversation recap").font(.system(size: 12, weight: .semibold))
                }
                Text("Jag läser en bok igår.").font(.system(size: 15)).foregroundStyle(ink.opacity(0.5))
                VStack(alignment: .leading, spacing: 5) {
                    Text("A LITTLE MORE NATURAL").font(.system(size: 8, weight: .bold)).tracking(1)
                        .foregroundStyle(ink.opacity(0.5))
                    Text("Jag läste en bok igår.").font(.system(size: 19, weight: .medium, design: .serif))
                }.padding(13).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: RoundedRectangle(cornerRadius: 15))
                Text("Try again").font(.system(size: 12, weight: .semibold)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 12).background(orange, in: Capsule())
            }.foregroundStyle(ink).padding(.horizontal, 20).padding(.top, 12)
        }
    }

    private var forms: some View {
        ZStack {
            Color(red: 0.87, green: 0.90, blue: 0.84)
            // Draw the cropped ring inside the panel so it cannot enlarge the caption group's accessibility frame.
            Canvas { context, _ in
                context.stroke(Path(ellipseIn: CGRect(x: 160, y: -120, width: 300, height: 300)),
                               with: .color(.white.opacity(0.4)), lineWidth: 1)
            }
            VStack(alignment: .leading, spacing: 13) {
                HStack(spacing: 7) {
                    Image(systemName: "character.book.closed.fill").foregroundStyle(Color(red: 0.31, green: 0.43, blue: 0.27))
                    Text("A WORD TAKES SHAPE").tracking(1.4)
                }.font(.system(size: 10, weight: .semibold)).foregroundStyle(ink.opacity(0.65))
                VStack(spacing: 9) {
                    HStack(spacing: 9) { formTile("en bok", detail: "a book"); formTile("boken", detail: "the book") }
                    HStack(spacing: 9) { formTile("böcker", detail: "books"); formTile("böckerna", detail: "the books") }
                }
            }.padding(.horizontal, 23)
        }
    }

    private func formTile(_ word: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word).font(.system(size: 24, weight: .medium, design: .serif))
            Text(detail).font(.system(size: 11)).foregroundStyle(ink.opacity(0.5))
        }.foregroundStyle(ink).frame(maxWidth: .infinity, alignment: .leading).padding(13)
            .background(paper, in: RoundedRectangle(cornerRadius: 16))
    }

    private var updates: some View {
        ZStack {
            tiles
            VStack(spacing: 15) {
                Image("ReleaseAppIcon").resizable().frame(width: 94, height: 94)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.12), radius: 14, y: 9)
                Text("What’s New").font(.system(size: 24, weight: .bold)).foregroundStyle(ink)
            }
        }
    }
}
