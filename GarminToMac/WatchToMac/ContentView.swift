import SwiftUI
import UniformTypeIdentifiers
import Combine

struct ContentView: View {
    // Lisans ve Deneme Süresi Yöneticisi
    @ObservedObject var trialManager = TrialManager.shared
    
    // Kullanıcı "Deneme ile devam et" dedi mi?
    @State private var showMainAppTemporary: Bool = false
    
    var body: some View {
        // 1. Eğer satın alınmışsa -> Direkt Ana Ekran
        if trialManager.isActivated {
            MainAppView()
                .transition(.opacity)
        }
        // 2. Eğer kullanıcı "Deneme Sürümünü Kullan" butonuna bastıysa -> Ana Ekran
        else if showMainAppTemporary {
             MainAppView()
                .transition(.opacity)
        }
        // 3. Aksi halde -> Lisans/Deneme Ekranı
        else {
            LicenseView(onContinueTrial: {
                withAnimation {
                    showMainAppTemporary = true
                }
            })
            .onAppear {
                trialManager.startTrialIfNeeded()
            }
        }
    }
}

// --- ANA UYGULAMA EKRANI ---
struct MainAppView: View {
    @StateObject private var manager = GarminManager.shared
    @ObservedObject var trialManager = TrialManager.shared
    
    // UI Durumları
    @State private var isFileImporterPresented = false
    @State private var isDropTargeted = false
    @State private var showInfoModal = false
    
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .overlay(isDropTargeted ? Color.blue.opacity(0.1) : Color.clear)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                // --- ÜST BAR ---
                HStack {
                    Button(action: { showInfoModal = true }) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("How to use")
                    
                    // GÜNCELLENMİŞ BAŞLIK
                    Text("WatchToMac MTP Manager")
                        .font(.title2)
                        .fontWeight(.bold)
                        .opacity(0.8)
                        .padding(.leading, 5)
                    
                    if !trialManager.isActivated {
                        Text("Trial Mode: \(trialManager.daysLeft) Days Left")
                            .font(.caption)
                            .padding(6)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button("Deactivate License") {
                        trialManager.isActivated = false
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(.gray)
                }
                .padding(.top, 20)
                .padding(.horizontal)
                
                // --- CİHAZ KARTI ---
                HStack(spacing: 15) {
                    ZStack(alignment: .bottomTrailing) {
                        
                        // --- YENİ RESİM MANTIĞI ---
                        // Hep 'image_9' görünür, bağlı değilse %50 silikleşir.
                        Image("image_9.png")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 55, height: 55)
                            .padding(5)
                            .background(manager.isConnected ? Color.gray.opacity(0.1) : Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            // İŞTE BURASI: Bağlıysa 1.0 (Net), Değilse 0.5 (Silik)
                            .opacity(manager.isConnected ? 1.0 : 0.5)
                        
                        // Durum Işığı
                        Circle()
                            .fill(manager.isConnected ? Color.green : Color.red)
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(manager.deviceName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(manager.isConnected ? "Ready to transfer" : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: { manager.toggleConnection() }) {
                            HStack {
                                Image(systemName: manager.isConnected ? "eject.fill" : "bolt.fill")
                                Text(manager.isConnected ? "Unmount" : "Mount").fontWeight(.bold)
                            }
                            .frame(width: 110)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(manager.isConnected ? .red.opacity(0.8) : .blue)
                        
                        if manager.isConnected {
                            Button(action: { manager.openInFinder() }) {
                                Label("Files", systemImage: "folder").font(.caption)
                            }
                            .buttonStyle(.bordered).controlSize(.small)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(nsColor: .controlBackgroundColor)))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                
                Spacer()
                
                // --- DROP ZONE ---
                VStack(spacing: 20) {
                    if manager.isUploading {
                        ProgressView().scaleEffect(1.2)
                        Text("Transferring...").font(.headline)
                    } else {
                        ZStack {
                            Circle().fill(isDropTargeted ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                                .frame(width: 160, height: 160)
                            VStack(spacing: 10) {
                                Image(systemName: "arrow.down.doc.fill").font(.system(size: 40))
                                    .foregroundColor(isDropTargeted ? .blue : .gray.opacity(0.4))
                                Text("Drop File Here").font(.headline).foregroundColor(.secondary)
                            }
                        }
                    }
                    Text(manager.statusMessage)
                        .font(.footnote)
                        .padding(8)
                        .background(Material.regular)
                        .cornerRadius(8)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(action: { isFileImporterPresented = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Select File (.prg / .fit / .mp3)")
                    }
                    .frame(maxWidth: .infinity).frame(height: 40)
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!manager.isConnected || manager.isUploading)
                .padding(.horizontal, 40).padding(.bottom, 30)
            }
        }
        .frame(minWidth: 520, minHeight: 600)
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item, .content, .data, .audio],
            allowsMultipleSelection: false
        ) { result in
            if let urls = try? result.get(), let url = urls.first {
                processURL(url)
            }
        }
        .sheet(isPresented: $showInfoModal) {
            InfoView()
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            if let first = providers.first {
                _ = first.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url { DispatchQueue.main.async { processURL(url) } }
                }
                return true
            }
            return false
        }
        .onReceive(timer) { _ in
            if !manager.isConnected && !manager.isUploading { manager.checkConnection(silent: true) }
        }
        .onAppear { manager.checkConnection(silent: false) }
    }
    
    func processURL(_ url: URL) {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
        
        do {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            manager.uploadFile(fileData: fileData, fileName: fileName)
        } catch {
            print("Dosya okuma hatası: \(error.localizedDescription)")
        }
    }
}
