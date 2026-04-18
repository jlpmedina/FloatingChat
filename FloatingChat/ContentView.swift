import SwiftUI
import Combine

struct Message: Identifiable {
    let id   = UUID()
    let role : String
    let text : String
    var isUser: Bool { role == "user" }
}

class ChatViewModel: ObservableObject {

    @Published var messages     : [Message] = []
    @Published var inputText    : String    = ""
    @Published var isLoading    : Bool      = false
    @Published var showSettings : Bool      = false

    var apiKey      : String
    var model       : String
    var systemPrompt: String

    init() {
        _messages     = Published(initialValue: [])
        _inputText    = Published(initialValue: "")
        _isLoading    = Published(initialValue: false)
        _showSettings = Published(initialValue: false)
        apiKey        = UserDefaults.standard.string(forKey: "apiKey")       ?? ""
        model         = UserDefaults.standard.string(forKey: "model")        ?? "gpt-4o-mini"
        systemPrompt  = UserDefaults.standard.string(forKey: "systemPrompt") ?? "Eres un asistente util y conciso. No uses Markdown."
    }

    func save() {
        UserDefaults.standard.set(apiKey,       forKey: "apiKey")
        UserDefaults.standard.set(model,        forKey: "model")
        UserDefaults.standard.set(systemPrompt, forKey: "systemPrompt")
    }

    func clear() { messages = [] }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        messages.append(Message(role: "user", text: text))
        inputText = ""
        isLoading = true

        let history = [ChatMessage(role: "system", content: systemPrompt)]
            + messages.filter { $0.role != "error" }.map { ChatMessage(role: $0.role, content: $0.text) }
        let key     = apiKey
        let modelID = model

        Task {
            do {
                let reply = try await OpenAIService.send(messages: history, apiKey: key, model: modelID)
                await MainActor.run {
                    self.messages.append(Message(role: "assistant", text: reply))
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.messages.append(Message(role: "error", text: error.localizedDescription))
                    self.isLoading = false
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var vm = ChatViewModel()
    @FocusState  private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Mini Chat").font(.headline)
                Spacer()
                if !vm.messages.isEmpty {
                    Button { vm.clear() } label: { Image(systemName: "trash") }
                        .buttonStyle(.borderless)
                }
                Button { vm.showSettings = true } label: { Image(systemName: "gear") }
                    .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial)

            Divider()

            // Mensajes
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
                            MessageBubble(message: msg).id(msg.id)
                        }
                        if vm.isLoading {
                            DotsIndicator().id("typing")
                        }
                    }
                    .padding(12)
                }
                .onChange(of: vm.messages.count) { oldValue, newValue in
                    withAnimation {
                        if let last = vm.messages.last { proxy.scrollTo(last.id) }
                    }
                }
                .onChange(of: vm.isLoading) { oldValue, newValue in
                    if newValue { withAnimation { proxy.scrollTo("typing") } }
                }
            }

            Divider()

            // Input
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Escribe un mensaje...", text: $vm.inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($focused)
                    .onSubmit {
                        if !NSEvent.modifierFlags.contains(.shift) { vm.send() }
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.5))

                Button { vm.send() } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.accentColor.opacity(0.4) : Color.accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                .disabled(vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(10)
        }
        .sheet(isPresented: $vm.showSettings) {
            SettingsSheet(vm: vm)
        }
        .onAppear { focused = true }
    }
}

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

    var background: Color {
        switch message.role {
        case "user":  return .accentColor
        case "error": return Color(nsColor: .systemRed).opacity(0.15)
        default:      return Color(nsColor: .controlBackgroundColor)
        }
    }
}

struct DotsIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .frame(width: 7, height: 7)
                    .foregroundStyle(Color.secondary)
                    .scaleEffect(animating ? 1.3 : 0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.18),
                               value: animating)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear { animating = true }
    }
}

struct SettingsSheet: View {
    @ObservedObject var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showKey = false
    let models = ["gpt-5.4-nano", "gpt-5.4-mini", "gpt-5.4", "gpt-3.5-turbo"]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ajustes").font(.title2).bold()

            VStack(alignment: .leading, spacing: 6) {
                Label("API Key", systemImage: "key").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Group {
                        if showKey { TextField("sk-...", text: $vm.apiKey) }
                        else        { SecureField("sk-...", text: $vm.apiKey) }
                    }
                    .textFieldStyle(.roundedBorder)
                    Button { showKey.toggle() } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }.buttonStyle(.borderless)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Modelo", systemImage: "cpu").font(.caption).foregroundStyle(.secondary)
                Picker("", selection: $vm.model) {
                    ForEach(models, id: \.self) { Text($0).tag($0) }
                }.pickerStyle(.menu).labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Instrucción del sistema", systemImage: "text.alignleft")
                    .font(.caption).foregroundStyle(.secondary)
                TextEditor(text: $vm.systemPrompt)
                    .frame(height: 80)
                    .overlay(RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            }

            Spacer()
            HStack {
                Spacer()
                Button("Cerrar") { vm.save(); dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 380, height: 360)
    }
}

