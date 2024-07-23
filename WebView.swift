import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let resourceName: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
         let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator // Set the navigation delegate
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let filePath = Bundle.main.path(forResource: resourceName, ofType: "html") {
            let fileURL = URL(fileURLWithPath: filePath)
            uiView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        } else {
            print("Failed to find the HTML file in the bundle.")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ webView: WebView) {
            self.parent = webView
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Page is fully loaded, now execute JavaScript
            webView.evaluateJavaScript("loadChartWithData('AAPL')", completionHandler: { result, error in
                if let error = error {
                    print("JavaScript execution error: \(error)")
                }
            })
        }
    }
}
    

struct WebView_Previews: PreviewProvider {
    static var previews: some View {
        WebView(resourceName: "chart") // Ensure 'chart.html' exists in your project and is correctly targeted
            .frame(width: 400, height: 600) // You can adjust the size to better fit your needs
    }
}
