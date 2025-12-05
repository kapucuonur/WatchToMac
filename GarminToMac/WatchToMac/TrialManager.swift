import Foundation
import SwiftUI
import Combine // Bu satır 'ObservableObject' hatasını çözer

class TrialManager: ObservableObject {
    static let shared = TrialManager()
    
    // Deneme süresi (Saniye cinsinden: 7 gün)
    // 7 gün * 24 saat * 60 dakika * 60 saniye
    private let trialDuration: TimeInterval = 7 * 24 * 60 * 60
    
    @AppStorage("firstLaunchDate") private var firstLaunchDate: Double = 0
    @AppStorage("isProVersion") var isActivated: Bool = false
    
    // Kalan gün sayısı
    var daysLeft: Int {
        if firstLaunchDate == 0 { return 7 }
        let elapsed = Date().timeIntervalSince1970 - firstLaunchDate
        let remaining = trialDuration - elapsed
        return max(0, Int(remaining / (24 * 60 * 60)))
    }
    
    // Süre bitti mi?
    var isTrialExpired: Bool {
        if isActivated { return false } // Satın aldıysa süre işlemez
        if firstLaunchDate == 0 { return false } // İlk açılışsa süre bitmemiştir
        
        let elapsed = Date().timeIntervalSince1970 - firstLaunchDate
        return elapsed > trialDuration
    }
    
    // Sayacı başlat
    func startTrialIfNeeded() {
        if firstLaunchDate == 0 {
            firstLaunchDate = Date().timeIntervalSince1970
        }
    }
}
