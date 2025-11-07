# Decrypt

Eine kleine Flutter‑App zum Verwalten von Kontakten und Schlüsseln (Public/Private), Erzeugen und Anzeigen von QR‑Codes sowie Verschlüsselungsfunktionen über einen internen Keystore.

## Voraussetzungen
- Flutter SDK (>= 3.9)
- Android SDK
- Geräteberechtigungen für Kamera (wenn QR‑Scanner benutzt werden will)

## Schnellstart
1. Abhängigkeiten installieren:
   ```
   flutter pub get
   ```
2. Auf einem verbundenen Gerät starten:
   ```
   flutter run -d (device_id)
   ```
3. Release‑APK (Android) bauen:
   ```
   flutter build apk --release
   ```

## Projektstruktur (wichtigste Dateien)
- lib/main.dart — App‑Start; initialisiert KeyStoreService und setzt die Routen.
- lib/screens/
  - login_page.dart — Registrierung / Login (Passwortverwaltung).
  - home_page.dart — Hauptansicht: eigener Public Key, Kontakte, Aktionen.
  - qr_scanner_page.dart — QR‑Scanner (falls vorhanden).
  - qr_dialog.dart — QR‑Dialog zur Anzeige / Teilen / Kopieren.
- lib/services/
  - keystore_service.dart — zentrale Logik zum Speichern/Verschlüsseln des Keystores.
  - cryptography.dart — kryptografische Hilfsfunktionen (Key‑Erzeugung, Verschlüsselung/Entschlüsselung).


## Wichtige Hinweise
- Keystore: KeyStoreService speichert einen Master‑Key im Secure Storage und verschlüsselt einen Blob in SharedPreferences. Beim Sperren (lock) werden Schlüssel aus dem Arbeitsspeicher entfernt, beim Entsperren (unlock) neu geladen.

## Entwicklung & Beiträge
- Für UI‑Änderungen sind die vorhanden Widgets in lib/screens vorgesehen

## Lizenz
Privates Projekt — nicht für Veröffentlichung vorgesehen (publish_to: 'none' im pubspec.yaml). Bei Bedarf Lizenz ergänzen.
