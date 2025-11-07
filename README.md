# Decrypt

Eine kleine Flutter‑App zum Verwalten von Kontakten und Schlüsseln (Public/Private), Erzeugen und Anzeigen von QR‑Codes sowie Verschlüsselungsfunktionen über einen internen Keystore.

## Voraussetzungen
- Flutter SDK (>= 3.9) (Empfohlen)
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

## Verwendete Technologien
- Framework: Flutter
- Programmiersprache: Dart
 #### Pakete / Libraries
- shared_preferences — lokale Key/Value‑Speicherung
- flutter_secure_storage — sicheres Speichern von Master‑Keys
- encrypt — AES‑Verschlüsselung (Blob‑Verschlüsselung)
- cryptography — kryptografische Hilfsfunktionen / Key‑Erzeugung
- qr_flutter — QR‑Code Erzeugung / Anzeige
- mobile_scanner / qr_code_scanner — QR‑Scanner
- share_plus — Teilen von Text / Daten
- cupertino_icons — Icons

## Mögliche Erweiterungen
- Chat-Verläufe speichern
- Push-Benachrichtigungen
- Synchronisation von Kontakten über Cloud
- Biometrische Entsperrung des Keystores

## Autoren
- Hans Kuntsche, Paul Weibbrecht
- Projekt im Rahmen des Moduls Web- und App-Programmierung (3MI-WAP-50)
- Duale Hochschule Sachsen, 2025


## Lizenz
Privates Projekt — nicht für Veröffentlichung vorgesehen
