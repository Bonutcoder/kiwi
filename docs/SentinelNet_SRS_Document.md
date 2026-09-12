# SentinelNet: Hardware-Verified Wi-Fi Trust Anchor
## Software Requirements Specification (SRS) & Product Requirements Document (PRD)

**Author:** Anurag Singh  
**Institution:** VIT University, Vellore  
**Date:** September 2026  

---

## 1. Project Context & Idea Overview
Public Wi-Fi networks are highly vulnerable to "Evil Twin" attacks, where malicious actors spoof legitimate SSIDs and present fake captive portals to harvest credentials. SentinelNet mitigates this by shifting the trust model from software to a physical hardware anchor. Using an ESP32 microcontroller as a cryptographic beacon (or inline router), public Wi-Fi networks can mathematically prove their legitimacy to a user's mobile device. If the hardware signature is absent or invalid, the network is immediately flagged as hostile.

## 2. Project Scope
The scope of this hackathon prototype includes:
*   A physical ESP32 microcontroller programmed via Arduino IDE acting as the Wi-Fi gateway/trust anchor.
*   A Flutter-based mobile application to initiate the cryptographic challenge, verify the response, and display the security status to the user.
*   Implementation of Ed25519 deterministic cryptography to prevent Man-in-the-Middle (MitM) and replay attacks.
*   An aggressive UI/UX flow on the mobile app ("Iron Gate") that prevents accidental connection to unverified networks.

## 3. Key Components
*   **Hardware Trust Anchor:** ESP32 operating in AP/Gateway mode running an asynchronous web server. Leverages C++ and low-level memory management.
*   **Cryptography Engine:** Ed25519 (via Southern_Storm_Crypto on ESP32, and the `cryptography` package on Flutter) utilizing 256-bit keys for low-latency, deterministic signing.
*   **Client App:** Flutter application handling network routing, cryptographic verification, and the user interface.

## 4. Product Requirements Document (PRD)
### 4.1 User Stories
*   As a user, I want my app to automatically detect if a public Wi-Fi network is legitimate so that my data is safe.
*   As a user, I want a clear, full-screen warning (Red Screen) if an Evil Twin is detected.
*   As a power user, I want the option to view the cryptographic handshake details for transparency.
*   As an advanced user, I want a hidden option to bypass the warning at my own risk.

### 4.2 UI/UX Requirements
*   **Verified State:** Clean, green UI indicating "Hardware Cryptography Verified."
*   **Hostile State:** Solid red `Scaffold` explicitly stating "Connection Blocked: No Hardware Signature Detected."
*   **Bypass Friction:** The "Connect Anyway" option must be nested inside an "Advanced Details" `ExpansionTile` to prevent accidental clicks.

## 5. System Architecture & Agents
*   **Mobile App Agent (Verifier):** Generates a random cryptographic nonce. Sends the challenge to the gateway IP via HTTP POST. Verifies the returned 64-byte signature against the pre-registered public key.
*   **Hardware Gateway Agent (Prover):** Listens for HTTP requests. Signs the incoming nonce using its hardcoded 32-byte Ed25519 private key. Returns the signature payload.

## 6. Security Specifications
*   **Algorithm:** Ed25519 (Edwards-curve Digital Signature Algorithm). Chosen over ECDSA P-256 to eliminate vulnerabilities associated with weak hardware Random Number Generators (RNGs) on microcontrollers.
*   **Replay Attack Prevention:** The *verifier* (Flutter app) generates the nonce, ensuring a fresh signature is required for every connection attempt.
*   **Key Management (Hackathon Demo):** Keys are pre-generated. The private key is hardcoded onto the ESP32. The corresponding public key is bundled into the Flutter application.

## 7. CI/CD Pipeline (Proposed)
*   **Source Control:** Git/GitHub repository.
*   **Firmware (ESP32):** Arduino-CLI workflow to compile the C++ sketch and verify library dependencies (e.g., `Crypto.h`) upon pull requests.
*   **Mobile App (Flutter):** GitHub Actions to run `flutter test` and build APK for Android testing automatically.
