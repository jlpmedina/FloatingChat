import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var vm = ChatViewModel()
    @FocusState private var focused: Bool

    private var isInputEmpty: Bool {
        vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Mini Chat")
                    .font(.headline)
                Spacer()
                if !vm.messages.isEmpty {
                    Button {
                        vm.clear()
                    } label: {
                        Image(systemName: "trash")
                    }
                        .buttonStyle(.borderless)
                        .keyboardShortcut("k", modifiers: .command)
                }
                Button {
                    vm.showSettings = true
                } label: {
                    Image(systemName: "gear")
                }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if vm.messages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right")
                                    .font(.system(size: 36)).foregroundStyle(.tertiary)
                                Text("¿En qué te puedo ayudar?")
                                    .font(.callout).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        }
                        ForEach(vm.messages) { msg in
                            MessageBubble(message: msg)
                                .id(msg.id)
                        }
                        if vm.isLoading {
                            DotsIndicator()
                                .id("typing")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: vm.messages.count) { _, _ in
                    withAnimation {
                        if let last = vm.messages.last {
                            proxy.scrollTo(last.id)
                        }
                    }
                }
                .onChange(of: vm.isLoading) { _, newValue in
                    if newValue {
                        withAnimation {
                            proxy.scrollTo("typing")
                        }
                    }
                }
            }

            Divider()

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Escribe un mensaje...", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onSubmit {
                        if !NSEvent.modifierFlags.contains(.shift) {
                            vm.send()
                        }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )

                Button {
                    vm.send()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            isInputEmpty
                                ? Color.accentColor.opacity(0.4)
                                : Color.accentColor
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                .disabled(isInputEmpty)
            }
            .padding(10)
        }
        .sheet(isPresented: $vm.showSettings) {
            SettingsSheet(vm: vm)
        }
        .onAppear { focused = true }
        .onReceive(NotificationCenter.default.publisher(for: .floatingChatShouldFocusInput)) { _ in
            focused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .floatingChatShouldClearConversation)) { _ in
            vm.clear()
        }
    }
}
