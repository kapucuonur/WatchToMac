import SwiftUI

struct LicenseView: View {
    // Deneme süresi yöneticisi
    @ObservedObject var trialManager = TrialManager.shared
    
    // Online lisans doğrulayıcı (Yeni oluşturduğumuz sınıf)
    private let validator = LicenseValidator()
    
    @State private var inputCode: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isChecking: Bool = false
    
    // --- BURAYI DEĞİŞTİR ---
    // Kendi Gumroad ürün sayfanın linkini buraya yapıştır.
    // Kullanıcı "Buy License" butonuna basınca buraya gidecek.
    let gumroadLink = URL(string: "https://2236586809450.gumroad.com/l/kdrbne")!
    // -----------------------
    
    // Ana ekrana geçişi sağlayan tetikleyici
    var onContinueTrial: () -> Void
    
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
            
            VStack(spacing: 25) {
                // --- İKON VE BAŞLIK ---
                Image(systemName: trialManager.isTrialExpired ? "lock.slash.fill" : "clock.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(trialManager.isTrialExpired ? .red : .orange)
                    .padding(.bottom, 10)
                
                Text(trialManager.isTrialExpired ? "Trial Expired" : "Free Trial Active")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if !trialManager.isTrialExpired {
                    Text("You have \(trialManager.daysLeft) days left to try the app.")
                        .foregroundColor(.secondary)
                } else {
                    Text("Your 7-day trial has ended. Please purchase a license to continue using the app.")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // --- SATIN ALMA BUTONU (GUMROAD) ---
                Link(destination: gumroadLink) {
                    HStack {
                        Image(systemName: "cart.fill")
                        Text("Buy License Key")
                    }
                    .frame(width: 200, height: 40)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.bottom, 10)
                
                Divider().frame(width: 200)
                
                // --- LİSANS AKTİVASYON KISMI ---
                VStack(spacing: 10) {
                    Text("Already have a key?").font(.caption).foregroundColor(.secondary)
                    
                    TextField("XXXX-XXXX-XXXX", text: $inputCode)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 14, design: .monospaced))
                        .frame(width: 300)
                        .multilineTextAlignment(.center)
                        .disabled(isChecking)
                    
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                    }
                    
                    Button(action: validateLicense) {
                        HStack {
                            if isChecking {
                                ProgressView().controlSize(.small)
                            }
                            Text("Activate Pro")
                                .fontWeight(.semibold)
                        }
                        .frame(width: 200, height: 30)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(inputCode.isEmpty || isChecking)
                }
                
                // --- DENEME SÜRÜMÜYLE DEVAM BUTONU ---
                // Sadece süre bitmediyse gösterilir
                if !trialManager.isTrialExpired {
                    Button("Continue with Trial") {
                        onContinueTrial()
                    }
                    .buttonStyle(.link)
                    .padding(.top, 10)
                }
            }
            .padding(40)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(20)
            .shadow(radius: 20)
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // --- LİSANS DOĞRULAMA FONKSİYONU ---
    func validateLicense() {
        // UI'ı kilitle
        isChecking = true
        showError = false
        errorMessage = ""
        
        // Boşlukları temizle (Kullanıcı kopyala yapıştır yaparken boşluk bırakmış olabilir)
        let cleanKey = inputCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validator sınıfını çağır
        validator.validate(licenseKey: cleanKey) { success, errorMsg in
            
            // UI güncellemeleri her zaman Main Thread'de yapılmalı
            DispatchQueue.main.async {
                self.isChecking = false
                
                if success {
                    // Başarılı: Pro modu aç ve ana ekrana geç
                    withAnimation {
                        trialManager.isActivated = true
                        onContinueTrial()
                    }
                } else {
                    // Başarısız: Hatayı göster
                    withAnimation {
                        self.showError = true
                        self.errorMessage = errorMsg ?? "Invalid License Key"
                    }
                }
            }
        }
    }
}
