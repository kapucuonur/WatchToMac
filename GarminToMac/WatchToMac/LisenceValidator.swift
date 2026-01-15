//
//  LisenceValidator.swift
//  WatchToMac
//
//  Created by Onur Kapucu on 7.1.2026.
//

import Foundation

class LicenseValidator {
    // --- BURAYI DEGISTIR ---
    // Gumroad linkinin sonundaki o kisa kod (Örn: "garminmac" veya "QweRty")
    private let productPermalink = "kdrbne"
    // -----------------------
    
    // MAKSİMUM CİHAZ LİMİTİ
    // Bir anahtar en fazla kaç kere aktive edilebilir?
    // Not: Kullanıcı bilgisayarına format atarsa 1 hak daha harcar.
    // O yüzden 5 yerine 10 gibi toleranslı bir sayı daha iyidir.
    private let maxAllowedUses = 5
    
    func validate(licenseKey: String, completion: @escaping (Bool, String?) -> Void) {
        // Gumroad Dogrulama Adresi
        guard let url = URL(string: "https://api.gumroad.com/v2/licenses/verify") else {
            completion(false, "System Error")
            return
        }
        
        // POST istegi hazirla (increment_uses_count=true demek sayacı 1 artır demektir)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyParams = "product_permalink=\(productPermalink)&license_key=\(licenseKey)&increment_uses_count=true"
        request.httpBody = bodyParams.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(false, "No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    
                    // 1. Anahtar gecerli mi?
                    if let success = json["success"] as? Bool, success == true {
                        
                        // 2. Kaç kere kullanılmış? (Gumroad bu sayıyı gönderir)
                        let uses = json["uses"] as? Int ?? 1
                        
                        // KORUMA MEKANİZMASI BURADA ÇALIŞIR
                        if uses > self.maxAllowedUses {
                            print("UYARI: Anahtar çok fazla kullanılmış! Sayaç: \(uses)")
                            completion(false, "This key has been used on too many devices. Limit is \(self.maxAllowedUses).")
                        } else {
                            // Sorun yok, limit aşılmamış
                            completion(true, nil)
                        }
                        
                    } else {
                        completion(false, "Invalid license key")
                    }
                }
            } catch {
                completion(false, "Verification failed")
            }
        }.resume()
    }
}
