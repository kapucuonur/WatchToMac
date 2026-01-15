//
//  InfoView.swift
//  WatchToMac
//
//  Created by Onur Kapucu on 7.1.2026.
//

import SwiftUI

struct InfoView: View {
    // Pencereyi kapatmak için gerekli değişken
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            // --- BAŞLIK KISMI ---
            HStack {
                Text("How to Use & Support")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // --- İÇERİK (SCROLL) ---
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    
                    // 1. ADIM: BAĞLANTI
                    InfoSection(
                        icon: "cable.connector",
                        color: .blue,
                        title: "1. Connect Your Device",
                        text: "Connect your Garmin watch to your Mac using the USB cable. Make sure the screen of your watch is unlocked."
                    )
                    
                    // 2. ADIM: MOUNT
                    InfoSection(
                        icon: "bolt.fill",
                        color: .orange,
                        title: "2. Mount the Device",
                        text: "Click the 'Mount' button in the app. Wait for the green indicator light. Your device name will appear automatically."
                    )
                    
                    // 3. ADIM: DOSYA AKTARIMI
                    InfoSection(
                        icon: "arrow.down.doc.fill",
                        color: .green,
                        title: "3. Transfer Files",
                        text: "You can drag & drop files (.mp3, .fit, .prg) directly into the circle area, or use the 'Select File' button."
                    )
                    
                    // 4. ADIM: UNMOUNT (ÖNEMLİ)
                    InfoSection(
                        icon: "eject.fill",
                        color: .red,
                        title: "4. Safely Disconnect",
                        text: "When finished, always click 'Unmount' before unplugging the USB cable to prevent data loss."
                    )
                    
                    Divider()
                    
                    // --- VERSİYON VE DESTEK ---
                    VStack(alignment: .center, spacing: 5) {
                        Text("WatchToMac MTP Manager v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Developed by You")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Link("Contact Support", destination: URL(string: "mailto:trihonor@hotmail.com")!)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .frame(width: 450, height: 600)
    }
}

// Tekrar eden tasarımı basitleştirmek için yardımcı görünüm
struct InfoSection: View {
    let icon: String
    let color: Color
    let title: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // Metni alt satıra geçir
            }
        }
    }
}
