import SwiftUI

struct ToastView: View {
    var message: String

    var body: some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray)
            .cornerRadius(8)
            .padding()
    }
}

struct ToastModifier: ViewModifier {
    @Binding var toast: Toast?
    @State private var workItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(
                viewBuilderOverlay()
                
            )
    }
    
    @ViewBuilder
    private func viewBuilderOverlay() -> some View {
        if let toast = toast {
            VStack {
                Spacer()
                ToastView(message: toast.message ?? "")
                    .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: toast)
            .onAppear {
                startToastTimer()
            }
        } else {
            EmptyView()
        }
    }

    private func startToastTimer() {
        guard let toast = toast, toast.duration > 0 else { return }
        workItem?.cancel()
        let task = DispatchWorkItem { [self] in
            self.dismissToast()
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: task)
    }

    private func dismissToast() {
        withAnimation {
            toast = nil
        }
        workItem?.cancel()
        workItem = nil
    }
}

extension View {
    func toastView(toast: Binding<Toast?>) -> some View {
        self.modifier(ToastModifier(toast: toast))
    }
}
