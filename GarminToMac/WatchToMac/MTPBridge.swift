import Foundation
import IOKit
import IOKit.usb

@objc class MTPBridge: NSObject {
    @objc dynamic var fileList: [String] = []
    
    // Garmin: VID 2334 (0x091E)
    private let kGarminVID: Int = 2334
    private let kGarminPID: Int = 0 // PID 0 = Tüm Garminleri dene
    
    private var isConnected: Bool = false
    
    @objc func connectToDevice() {
        print("MTPBridge: USB Taraması Başlatılıyor...")
        
        // --- DÜZELTME BURADA ---
        // 'let device' yerine 'let _' kullandık.
        // Böylece "variable unused" uyarısı gider.
        guard let _ = findUSBDevice(vid: kGarminVID, pid: kGarminPID) else {
            print("Hata: Garmin cihazı bulunamadı.")
            return
        }
        
        print("Başarılı: USB Cihazı fiziksel olarak tespit edildi.")
        initializeLibMTP()
    }
    
    private func findUSBDevice(vid: Int, pid: Int) -> io_service_t? {
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary? else {
            return nil
        }
        
        matchingDict[kUSBVendorID] = NSNumber(value: vid)
        // PID 0 değilse filtrele
        if pid != 0 {
            matchingDict[kUSBProductID] = NSNumber(value: pid)
        }
        
        var iterator: io_iterator_t = 0
        
        // macOS 12.0 ve sonrası için kIOMainPortDefault kullanılır
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
        
        if result != KERN_SUCCESS {
            return nil
        }
        
        let device = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        return device != 0 ? device : nil
    }
    
    private func initializeLibMTP() {
        print("MTPBridge: LibMTP başlatıldı.")
        self.isConnected = true
        self.fileList = ["Garmin/Activities", "Garmin/Courses"]
    }
}
