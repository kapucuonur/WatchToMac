import SwiftUI

// Bu sınıf, uygulama kapanırken (Terminate) devreye girer
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        // Uygulama kapanırken (CMD+Q) Timer'ı durdur ve Unmount yap
        print("⚠️ Uygulama kapatılıyor (Terminate Signal).")
        GarminManager.shared.stopScanning()
    }
}

@main
struct WatchToMacApp: App {
    // AppDelegate'i sisteme tanıtıyoruz
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300) // Pencere boyutu sabitleme
        }
        // Menü çubuğundan Quit dendiğinde de tetiklenmesi için
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Çıkış Yap") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
        }
    }
}
