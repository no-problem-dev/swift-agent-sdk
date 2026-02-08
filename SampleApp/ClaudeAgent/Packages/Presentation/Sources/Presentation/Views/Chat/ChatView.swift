import SwiftUI

/// メッセージ一覧 + 入力エリア
struct ChatView: View {
    @Bindable var session: SessionState

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(session.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        if !session.streamingText.isEmpty {
                            StreamingTextView(text: session.streamingText)
                                .id("streaming")
                        }
                    }
                    .padding()
                }
                .onChange(of: session.messages.count) {
                    if let last = session.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: session.streamingText) {
                    if !session.streamingText.isEmpty {
                        withAnimation {
                            proxy.scrollTo("streaming", anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
            InputArea(session: session)
        }
    }
}
