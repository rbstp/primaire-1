# Mission Ninja build helpers. The Xcode project is generated from project.yml.
#
#   make project    generate MissionNinja.xcodeproj (needs `brew install xcodegen`)
#   make test       unit tests on the simulator
#   make run        build, install and launch on the iPhone simulator
#   make ipad       same, on an iPad simulator
#   make shot       screenshot of the booted simulator into .build/
#   make icon       regenerate the app icon PNG
#   make archive    Release archive (needs the Apple Distribution cert + profile)
#   make upload     upload the archive to TestFlight (needs API_KEY, API_KEY_ID, API_ISSUER)
#   make lsp        buildServer.json so Zed, VS Code and Neovim resolve types across files

SCHEME     := MissionNinja
PROJECT    := MissionNinja.xcodeproj
BUNDLE_ID  := dev.rbstp.missionninja
SIM        ?= iPhone 17 Pro Max
IPAD_SIM   ?= iPad Pro 13-inch (M5)
DEST       := platform=iOS Simulator,name=$(SIM)
BUILD      := .build
DERIVED    := $(BUILD)/DerivedData
APP        := $(DERIVED)/Build/Products/Debug-iphonesimulator/MissionNinja.app
ARCHIVE    := $(BUILD)/MissionNinja.xcarchive
ICON       := Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
VERSION    ?= 0.1.0
BUILD_NUM  ?= 1

XCB := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED)

.PHONY: all project build test run ipad shot icon archive upload lsp clean

all: test

# Always run: adding a source file changes the project even though project.yml
# did not. --use-cache leaves the pbxproj untouched when nothing changed, so
# Xcode keeps its build cache.
project:
	@mkdir -p $(BUILD)
	xcodegen generate --use-cache --cache-path $(BUILD)/xcodegen.cache

build: project
	$(XCB) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO build

test: project
	$(XCB) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO test

run: build
	xcrun simctl boot "$(SIM)" 2>/dev/null || true
	open -a Simulator 2>/dev/null || true
	xcrun simctl install booted "$(APP)"
	xcrun simctl launch booted $(BUNDLE_ID)

ipad:
	$(MAKE) run SIM="$(IPAD_SIM)"

shot:
	@mkdir -p $(BUILD)
	xcrun simctl io booted screenshot "$(BUILD)/shot-$$(date +%H%M%S).png"

icon:
	@mkdir -p $(BUILD)
	swiftc -O -o $(BUILD)/generate-icon scripts/icon/main.swift Sources/MissionNinja/Theme/Paint.swift
	$(BUILD)/generate-icon "$(ICON)"

archive: project
	$(XCB) -destination 'generic/platform=iOS' -configuration Release \
		-archivePath "$(ARCHIVE)" \
		MARKETING_VERSION="$(VERSION)" CURRENT_PROJECT_VERSION="$(BUILD_NUM)" archive

# API_KEY is the path to the App Store Connect .p8 file.
upload:
	@test -n "$(API_KEY)" -a -n "$(API_KEY_ID)" -a -n "$(API_ISSUER)" || { \
		echo "usage: make upload API_KEY=path/to/AuthKey.p8 API_KEY_ID=XXXX API_ISSUER=uuid"; exit 1; }
	xcodebuild -exportArchive -archivePath "$(ARCHIVE)" \
		-exportOptionsPlist scripts/ExportOptions.plist -exportPath "$(BUILD)/export" \
		-authenticationKeyPath "$(API_KEY)" -authenticationKeyID "$(API_KEY_ID)" \
		-authenticationKeyIssuerID "$(API_ISSUER)"

lsp: project
	@command -v xcode-build-server >/dev/null || { echo "brew install xcode-build-server"; exit 1; }
	xcode-build-server config -project $(PROJECT) -scheme $(SCHEME)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO build

clean:
	rm -rf $(BUILD) $(PROJECT) buildServer.json
