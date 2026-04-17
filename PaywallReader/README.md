# PaywallReader (iOS)

Native iOS app + Share Extension die via een keten van archief-diensten probeert
paywalls te omzeilen en het artikel in reader-weergave aanbiedt.

## Status

- **Phase 1**: projectstructuur, lokale `UnlockKit` SPM-package, main app met
  uitleg-scherm, Share Extension die "Hallo vanuit PaywallReader" toont met de
  gedeelde URL.
- Phase 2: archive.is + Wayback strategieën (unlock chain).
- Phase 3: SFSafariViewController reader + settings UI + error states.

## Vereisten

- macOS met Xcode 15+
- iOS 17 deployment target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

Het `.xcodeproj` wordt niet ingecheckt — regenereer lokaal met XcodeGen.

## Project openen

```sh
cd PaywallReader
xcodegen generate
open PaywallReader.xcodeproj
```

## Builds vanaf command line

```sh
cd PaywallReader
xcodegen generate
xcodebuild -scheme PaywallReader -destination 'generic/platform=iOS Simulator' build
```

Tests (runt de SwiftPM tests van `UnlockKit`):

```sh
cd PaywallReader/Packages/UnlockKit
swift test
```

## Structuur

```
PaywallReader/
  project.yml                     # XcodeGen project-spec
  PaywallReader/                  # Main app target (SwiftUI)
  ShareExtension/                 # Share Extension target (SwiftUI + UIKit host)
  Packages/UnlockKit/             # Lokale SPM package met unlock-logica
```

## Ontwikkelteam

Voor het draaien op een fysiek apparaat of distributie moet `DEVELOPMENT_TEAM`
in `project.yml` worden ingevuld en moet de App Group
`group.com.floorvanriet.PaywallReader` in het Apple Developer portal staan.
Voor simulator-builds kan dit leeg blijven.
