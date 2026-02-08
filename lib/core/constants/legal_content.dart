/// محتوى قانوني للتطبيق
/// يحتوي على Privacy Policy و Terms of Service
class LegalContent {
  LegalContent._();

  /// سياسة الخصوصية
  static String get privacyPolicy => '''
# Privacy Policy

**Last Updated:** ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

## Zero Data Collection

**Sada** is a **decentralized, offline mesh messenger**. We (the developers) **cannot see, store, or process** any of your messages, contacts, or data.

### What We Don't Collect

- **No Messages**: All messages are encrypted end-to-end and stored locally on your device only.
- **No Contacts**: Your contact list exists only on your device.
- **No Metadata**: We don't have servers, so there are no server logs, connection logs, or metadata trails.
- **No Analytics**: We don't track your usage, location, or behavior.
- **No Account Information**: User registration is device-bound and offline-only.

### What You Control

- **Local Storage**: All data (messages, contacts, keys) is stored on your device using **Drift (SQLite)**.
- **Encryption Keys**: Your private keys are stored securely in your device's **Android Keystore** (encrypted storage).
- **Duress Mode**: You can use a "Duress PIN" to access a dummy database, providing plausible deniability.

## Mesh Networking

**Sada** uses **WiFi Direct (P2P)** and **Bluetooth LE** to create a mesh network. Messages are:

1. **Encrypted** using **X25519** key exchange and **XSalsa20-Poly1305** authenticated encryption.
2. **Routed** through other devices in the mesh network to reach the destination.
3. **Not stored** on intermediate devices (they only forward encrypted packets).

### Important Notes

- Messages pass through other users' devices, but they are **encrypted** and cannot be read.
- We cannot control or monitor the mesh network routing.
- Network topology is dynamic and peer-to-peer.

## Open Source

**Sada** is **open source** (MIT License). You can:

- Review the source code: [GitHub Repository](https://github.com/obadadallo95/sada-messenger)
- Audit the encryption implementation.
- Verify that no data collection occurs.

## Your Responsibility

- **Backup Your Keys**: If you lose your device, you lose access to your messages (by design, for security).
- **Secure Your Device**: Use biometric lock and strong PINs.
- **Legal Use**: Do not use Sada for illegal activities.

## Changes to This Policy

We may update this Privacy Policy. Changes will be reflected in the app's "About" screen.

---

**Questions?** Open an issue on [GitHub](https://github.com/obadadallo95/sada-messenger/issues).
''';

  /// شروط الاستخدام
  static String get termsOfService => '''
# Terms of Service

**Last Updated:** ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}

## Alpha Software Disclaimer

**Sada** is currently in **Alpha** (v1.0). This software is provided "as is" without warranty of any kind.

### Use at Your Own Risk

- **No Guarantees**: We do not guarantee message delivery, network availability, or data persistence.
- **No Support**: This is experimental software. Use at your own risk.
- **No Liability**: The developers are not liable for any loss of data, messages, or damages.

## Acceptable Use

### You May:

- Use Sada for personal, non-commercial communication.
- Review and modify the source code (MIT License).
- Share the app with others (offline APK sharing).

### You Must Not:

- **Illegal Activities**: Do not use Sada for illegal purposes, including but not limited to:
  - Terrorism or violence
  - Drug trafficking
  - Human trafficking
  - Fraud or scams
  - Harassment or threats

- **Harmful Content**: Do not share:
  - Malware or viruses
  - Child exploitation material
  - Hate speech or discrimination

- **Network Abuse**: Do not:
  - Intentionally disrupt the mesh network
  - Spam or flood the network
  - Attempt to decrypt others' messages

## Open Source License

**Sada** is licensed under the **MIT License**:

```
MIT License

Copyright (c) 2025 Obada Dallo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## No Warranty

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.**

## Termination

We reserve the right to terminate or restrict access to the software for users who violate these terms.

## Changes to Terms

We may update these Terms of Service. Continued use of the app constitutes acceptance of the updated terms.

---

**Questions?** Open an issue on [GitHub](https://github.com/obadadallo95/sada-messenger/issues).
''';
}

