import SwiftUI

struct SettingsSheet: View {
    @ObservedObject var vm: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showKey = false
    @State private var form: ChatSettingsForm

    init(vm: ChatViewModel) {
        self.vm = vm
        _form = State(initialValue: vm.makeSettingsForm())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ajustes")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 6) {
                Label("API Key", systemImage: "key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Group {
                        if showKey {
                            TextField("sk-...", text: $form.apiKey)
                        } else {
                            SecureField("sk-...", text: $form.apiKey)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button {
                        showKey.toggle()
                    } label: {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Modelo", systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $form.model) {
                    ForEach(AppConfiguration.supportedModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("Instrucción del sistema", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $form.systemPrompt)
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
                    )
            }

            if let error = vm.settingsErrorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancelar") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Guardar") {
                    if vm.applySettings(form) {
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380, height: 360)
    }
}