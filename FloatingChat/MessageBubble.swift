import SwiftUI

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            Text(message.text)
                .font(.body)
                .foregroundStyle(message.isUser ? .white : .primary)
                .textSelection(.enabled)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    private var background: Color {
        switch message.role {
        case "user":
            return .accentColor
        case "error":
            return Color(nsColor: .systemRed).opacity(0.15)
        default:
            return Color(nsColor: .controlBackgroundColor)
        }
    }
}

struct DotsIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundStyle(Color.secondary)
                    .scaleEffect(animating ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.18),
                        value: animating
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { animating = true }
    }
}