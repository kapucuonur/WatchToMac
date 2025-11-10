import Foundation
import Combine
import AppKit

class GarminManager: ObservableObject {
    static let shared = GarminManager()
    
    @Published var isConnected: Bool = false
    @Published var deviceName: String = "Searching..."
    @Published var statusMessage: String = "Ready"
    @Published var isUploading: Bool = false
    
    private var detectedStorageRoot: String?
    private var userIntendedDisconnect = false
    private let mountFolderName = "GarminMount"
    
    private var mountPoint: String {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(mountFolderName).path
    }
    
    private var binaryPath: String? {
        Bundle.main.path(forResource: "jmtpfs", ofType: nil)
    }
    
    func stopScanning() { disconnectDevice() }

    // --- 1. HIZLI BAŞLANGIÇ (FAST CHECK) ---
    // Bu fonksiyon sadece "Dosya var mı?" diye bakar, derin analiz yapmaz.
    func fastCheckConnection() {
        if userIntendedDisconnect { return }
        
        // Burayı 'userInitiated' (Yüksek Öncelik) yaptık
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            var isDir: ObjCBool = false
            
            // Klasör var mı?
            if fm.fileExists(atPath: self.mountPoint, isDirectory: &isDir) && isDir.boolValue {
                do {
                    // İçinde dosya var mı? (Sadece 1 tane bile olsa yeter)
                    let files = try fm.contentsOfDirectory(atPath: self.mountPoint)
                    if !files.isEmpty {
                        // BİNGO! ANINDA YEŞİL IŞIK YAK
                        DispatchQueue.main.async {
                            if !self.isConnected {
                                self.isConnected = true
                                self.statusMessage = "Connected"
                                self.deviceName = "Garmin Device" // Geçici isim
                            }
                        }
                        
                        // İsim bulma işini SONRA yap (Kullanıcıyı bekletme)
                        self.performDeepScanInBackground()
                        return
                    }
                } catch {
                    // Hata varsa sessiz kal, döngü tekrar deneyecek
                }
            }
        }
    }
    
    // --- 2. ARKA PLAN TARAMASI (LAZY SCAN) ---
    private func performDeepScanInBackground() {
        DispatchQueue.global(qos: .utility).async {
            let scanResult = self.findModelNameDeepScan(rootPath: self.mountPoint)
            let fm = FileManager.default
            let isWritable = fm.isWritableFile(atPath: self.mountPoint)
            
            DispatchQueue.main.async {
                // Sadece bağlıysak güncelle
                if self.isConnected {
                    // Gerçek ismi ve durumu güncelle
                    if scanResult.name != "Garmin Device" {
                         self.deviceName = scanResult.name
                    }
                    self.detectedStorageRoot = scanResult.rootPath
                    self.statusMessage = isWritable ? "Ready" : "Read-Only"
                }
            }
        }
    }

    // --- 3. BAĞLANMA (TURBO MOD) ---
    func toggleConnection() {
        if isConnected { disconnectDevice() } else { userIntendedDisconnect = false; connectDevice() }
    }

    private func connectDevice() {
        guard let binary = binaryPath else {
            self.statusMessage = "Error: jmtpfs binary not found."
            return
        }
        
        DispatchQueue.main.async { self.statusMessage = "Connecting..." }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.forceCleanup() // Temizlik
            try? FileManager.default.createDirectory(atPath: self.mountPoint, withIntermediateDirectories: true)
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: binary)
            
            let uid = getuid()
            let gid = getgid()
            let options = "allow_other,noappledouble,nolocalcaches,rw,uid=\(uid),gid=\(gid),iosize=1048576"
            task.arguments = ["-f", "-o", options, self.mountPoint]
            
            var env = ProcessInfo.processInfo.environment
            env["DYLD_LIBRARY_PATH"] = Bundle.main.resourcePath
            task.environment = env
            
            task.standardOutput = FileHandle.nullDevice
            task.standardError = FileHandle.nullDevice
            
            do {
                try task.run()
                
                // --- ÇOK HIZLI KONTROL DÖNGÜSÜ ---
                // 0.1 saniyede bir kontrol et (Maksimum hız)
                for _ in 0..<40 { // 4 saniye limit
                    Thread.sleep(forTimeInterval: 0.1)
                    
                    if task.isRunning {
                        // Klasör doldu mu diye bak (Hafif kontrol)
                        let content = try? FileManager.default.contentsOfDirectory(atPath: self.mountPoint)
                        if let files = content, !files.isEmpty {
                            // Dolduğu an bağlandı say
                            self.fastCheckConnection()
                            return
                        }
                    } else {
                        break
                    }
                }
                // Son bir kontrol
                self.fastCheckConnection()
                
            } catch {
                DispatchQueue.main.async { self.statusMessage = "Failed: \(error.localizedDescription)" }
            }
        }
    }
    
    // --- MODEL BULMA (Değişmedi) ---
    private func findModelNameDeepScan(rootPath: String) -> (name: String, rootPath: String?) {
        let fileManager = FileManager.default
        let targetFile = "GarminDevice.xml"
        let quickPaths = [
            rootPath + "/Garmin/" + targetFile,
            rootPath + "/Internal Storage/Garmin/" + targetFile,
            rootPath + "/Internal Storage/GARMIN/" + targetFile,
            rootPath + "/Primary/Garmin/" + targetFile
        ]
        for path in quickPaths {
            if let name = parseXML(path: path) {
                let root = URL(fileURLWithPath: path).deletingLastPathComponent().deletingLastPathComponent().path
                return (name, root)
            }
        }
        if let enumerator = fileManager.enumerator(at: URL(fileURLWithPath: rootPath), includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if enumerator.level > 4 { enumerator.skipDescendants(); continue }
                if fileURL.lastPathComponent.caseInsensitiveCompare(targetFile) == .orderedSame {
                    if let name = parseXML(path: fileURL.path) {
                        let root = fileURL.deletingLastPathComponent().deletingLastPathComponent().path
                        return (name, root)
                    }
                }
            }
        }
        return ("Garmin Device", nil)
    }
    
    private func parseXML(path: String) -> String? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            if let rangeStart = content.range(of: "<Description>"),
               let rangeEnd = content.range(of: "</Description>", range: rangeStart.upperBound..<content.endIndex) {
                return String(content[rangeStart.upperBound..<rangeEnd.lowerBound])
            }
        } catch { return nil }
        return nil
    }

    // --- KOPARMA ---
    func disconnectDevice() {
        DispatchQueue.main.async { self.statusMessage = "Disconnecting..." }
        userIntendedDisconnect = true
        
        let script = "tell application \"Finder\" to close (every window whose target is POSIX file \"\(mountPoint)\")"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.forceCleanup()
            DispatchQueue.main.async {
                self.isConnected = false
                self.deviceName = "Disconnected"
                self.statusMessage = "Disconnected."
                self.detectedStorageRoot = nil
            }
        }
    }

    private func forceCleanup() {
        let unmount = Process()
        unmount.executableURL = URL(fileURLWithPath: "/usr/sbin/diskutil")
        unmount.arguments = ["unmount", "force", mountPoint]
        try? unmount.run()
        unmount.waitUntilExit()
        
        let kill = Process()
        kill.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        kill.arguments = ["-9", "jmtpfs"]
        try? kill.run()
        kill.waitUntilExit()
        
        if FileManager.default.fileExists(atPath: mountPoint) {
            try? FileManager.default.removeItem(atPath: mountPoint)
        }
    }

    func openInFinder() {
        if isConnected { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: mountPoint) }
    }
    
    // --- 4. UPLOAD (Değişmedi) ---
    func uploadFile(fileData: Data, fileName: String) {
        guard isConnected else { return }
        DispatchQueue.main.async { self.isUploading = true; self.statusMessage = "Writing..." }
        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default
            let ext = (fileName as NSString).pathExtension.lowercased()
            var attempts: [String] = []
            
            if let root = self.detectedStorageRoot {
                if ["mp3", "m4b", "aac", "wav"].contains(ext) {
                    attempts.append(root + "/Music/" + fileName)
                    attempts.append(root + "/Audiobooks/" + fileName)
                    attempts.append(root + "/GARMIN/Music/" + fileName)
                } else if ext == "prg" {
                    attempts.append(root + "/GARMIN/Apps/" + fileName)
                } else if ext == "fit" {
                    attempts.append(root + "/GARMIN/NewFiles/" + fileName)
                }
            }
            attempts.append(contentsOf: [
                self.mountPoint + "/Internal Storage/Music/" + fileName,
                self.mountPoint + "/Music/" + fileName,
                self.mountPoint + "/" + fileName
            ])
            
            var success = false
            var lastError = "Unknown"
            
            for dest in attempts {
                let folder = URL(fileURLWithPath: dest).deletingLastPathComponent()
                try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
                do {
                    try fileData.write(to: URL(fileURLWithPath: dest), options: .atomic)
                    success = true
                    break
                } catch { lastError = error.localizedDescription }
            }
            DispatchQueue.main.async {
                self.isUploading = false
                if success { self.statusMessage = "✅ Success: \(fileName)" }
                else { self.statusMessage = "Err: \(lastError.prefix(30))..." }
            }
        }
    }
    
    // --- (Eski checkConnection'ı timer için tutuyoruz ama içi boşaltıldı) ---
    func checkConnection(silent: Bool) {
        // Timer çağırırsa fastCheck yap
        fastCheckConnection()
    }
}
