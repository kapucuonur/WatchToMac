# WatchToMac (GarminToMac)

[![Get it on Gumroad](https://img.shields.io/badge/Get%20it%20on-Gumroad-ff90e8?style=for-the-badge&logo=gumroad&logoColor=black)](https://2236586809450.gumroad.com/l/kdrbne)

WatchToMac is a macOS application built with SwiftUI that helps connect and manage your Garmin Watch natively on your Mac. Using MTP (Media Transfer Protocol) bridging, it reliably detects, unmounts, and interacts with Garmin devices connected via USB.

## Features
- **Native macOS UI:** Built entirely in SwiftUI for a seamless experience on macOS.
- **Garmin Device Detection:** Automatically scans and detects connected Garmin watches.
- **MTP Bridge Integration:** Manages USB connections cleanly, handling mounting and unmounting seamlessly.
- **Trial & License Management:** Built-in support for standard application licensing and trial periods.

## Requirements
- macOS 13.0+ (or newer, depending on the SwiftUI features used)
- Xcode 15.0+ 

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/WatchToMac.git
   ```
2. **Open the project:**
   Open `GarminToMac/GarminToMac.xcodeproj` in Xcode.
   
3. **Build and Run:**
   Select your primary Mac as the run destination and hit `Cmd + R` to build and run the application.

## Project Structure
- **WatchToMacApp:** The main SwiftUI entry point of the application.
- **WatchManager / MTPBridge:** Core logic handling the hardware communication with your Garmin device.
- **ContentView:** The primary user interface.
- **TrialManager / LicenseValidator:** Logic for managing application usage rights.

## Contributing
Contributions are welcome. Feel free to open an issue or submit a pull request!
