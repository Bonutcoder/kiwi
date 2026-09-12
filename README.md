# Kiwi: Hardware-Verified Wi-Fi Trust Anchor 🥝📶


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-Client-02569B?logo=flutter)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/ESP32-Hardware%20Anchor-E7352C?logo=espressif)](https://www.espressif.com/)
[![Ed25519](https://img.shields.io/badge/Cryptography-Ed25519-green.svg)](https://ed25519.cr.yp.to/)

Kiwi shifts the public Wi-Fi trust model from vulnerable software-level assumptions to a **physical hardware anchor**. 

Using an ESP32 microcontroller as a cryptographic beacon and gateway, public Wi-Fi networks mathematically prove their legitimacy to a user's mobile device via deterministic **Ed25519 challenge-response signing**. If the cryptographic proof is absent, forged, or invalid (such as in an **Evil Twin** or rogue captive portal attack), the client application activates an aggressive **"Iron Gate"** lockdown to protect user credentials and network traffic.

---

## 📌 Problem Statement

Public Wi-Fi networks (e.g., at airports, cafes, or railway stations) are susceptible to **Evil Twin attacks**:
1. Malicious actors spoof legitimate SSIDs (e.g., `Railway_Free_WiFi`).
2. Devices connect automatically based on SSID matching.
3. Fake captive portals harvest personal credentials or intercept unencrypted traffic.

Traditional countermeasures (WPA2/3 Enterprise, 802.1X certificates) are cumbersome, rarely supported on open public hotspots, and vulnerable to misconfiguration by non-technical users.

---

## 💡 The Kiwi Solution

Kiwi introduces an out-of-band cryptographic handshake executed strictly over the Local Area Network (LAN):
- **Zero Internet Dependency:** The verification happens directly over the local network created by the ESP32 gateway.
- **Deterministic Cryptography:** Uses **Ed25519** (256-bit Edwards-curve Digital Signature Algorithm), avoiding vulnerabilities associated with weak pseudo-random number generation on microcontrollers.
- **Replay Protection:** The mobile client (verifier) generates a unique single-use cryptographic **nonce** for every connection attempt.
- **"Iron Gate" UX:** A high-friction mobile interface that blocks network access on verification failure, displaying a full-screen red warning with intentional friction before allowing any bypass.

---

## 🔄 System Architecture & Data Flow

```
[ Flutter Mobile App (Verifier) ]                            [ ESP32 Hardware (Prover) ]
           |                                                              |
           |--- 1. Connects to SSID (e.g., 'Railway_Free_WiFi') --------->|
           |                                                              |
           |<-- 2. Local IP Assigned via DHCP (e.g., 192.168.4.2) --------|
           |                                                              |
           |--- 3. Generates Random Nonce (e.g., "challenge_9A4bX")       |
           |--- 4. HTTP POST /verify { "nonce": "challenge_9A4bX" } ----->|
           |                                                              |
           |                                                 [ Hashes Nonce ]
           |                                                 [ Signs with 32B Private Key ]
           |<-- 5. HTTP 200 OK { "signature": [64-byte array] } ----------|
           |                                                              |
[ Verifies Signature with Public Key ]                                    |
[ Updates UI: Green (Verified) / Red (Hostile) ]                          |
```

---

## 📂 Repository Structure

```text
kiwi/
├── docs/                                  # Specifications and design documents
├── firmware/                              # ESP32 C++ / Arduino sketch
│   └── kiwi_trust_anchor/                 # AP mode & Ed25519 signing web server
├── mobile_app/                            # Flutter mobile verifier client
│   ├── lib/                               # Application source code
│   └── test/                              # Cryptographic unit tests
├── .gitignore                             # Git ignore configuration
└── README.md                              # Project overview
```

---

## 🧰 Tech Stack

| Component | Technology | Purpose |
| :--- | :--- | :--- |
| **Hardware Gateway** | ESP32 (NodeMCU / DevKit) | Physical Trust Anchor & SoftAP |
| **Firmware Framework** | C++ / Arduino IDE / ESP-IDF | Low-level execution & AP management |
| **Firmware Crypto** | Southern_Storm_Crypto (`Crypto.h`) | Hardware-optimized Ed25519 signing |
| **Client App** | Flutter / Dart | Cross-platform mobile verifier & UI |
| **Client Crypto** | `cryptography` package (Dart) | Ed25519 signature verification |
| **Networking** | `http` package (Dart) | Local gateway challenge-response communication |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (3.x+) & Android Studio / VS Code
- **Arduino IDE** (or PlatformIO) with ESP32 board definitions installed
- An **ESP32 development board** and a micro-USB/Type-C data cable

---

### 1. Hardware & Firmware Setup (`/firmware`)
1. Open the Arduino IDE.
2. Go to **Tools > Manage Libraries...** and search for **`Crypto` by Rhys Weatherley** (`Southern_Storm_Crypto`). Install it.
3. Open `firmware/kiwi_trust_anchor/kiwi_trust_anchor.ino`.
4. Flash the sketch to the ESP32.
5. The ESP32 will broadcast an Access Point (default: `Kiwi_WiFi`) and listen for verification challenges on `http://192.168.4.1/verify`.

---

### 2. Mobile App Setup (`/mobile_app`)
1. Navigate to the mobile app directory:
   ```bash
   cd mobile_app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the cryptographic verification tests:
   ```bash
   flutter test
   ```
4. Launch the app on an Android device or emulator:
   ```bash
   flutter run
   ```

---

## 🧪 Verification & Demo Walkthrough

1. **Legitimate Network Demo (Green State):**
   - Connect the mobile device to the ESP32 Wi-Fi AP.
   - Open Kiwi and tap **Verify Network**.
   - The app exchanges the nonce challenge with the ESP32, verifies the signature against the pre-bundled public key, and transitions to the **Green ("Hardware Cryptography Verified")** screen.

2. **Evil Twin Simulation (Red State):**
   - Turn on a mobile hotspot with the exact same SSID as the ESP32.
   - Disconnect the ESP32 or connect the client to the hotspot.
   - Tap **Verify Network**.
   - The rogue AP fails to return a valid Ed25519 signature, immediately triggering the **Red ("Connection Blocked: No Hardware Signature Detected")** "Iron Gate" screen.

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.
