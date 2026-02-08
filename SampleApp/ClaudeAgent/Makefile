.PHONY: generate build test clean

generate:
	xcodegen generate

build: build-domain build-infrastructure build-presentation build-app

build-domain:
	swift build --package-path Packages/Domain

build-infrastructure:
	swift build --package-path Packages/Infrastructure

build-presentation:
	swift build --package-path Packages/Presentation

build-app: generate
	xcodebuild build -project ClaudeAgent.xcodeproj -scheme ClaudeAgent -destination 'platform=macOS'

test: test-domain test-infrastructure test-presentation

test-domain:
	swift test --package-path Packages/Domain

test-infrastructure:
	swift test --package-path Packages/Infrastructure

test-presentation:
	swift test --package-path Packages/Presentation

clean:
	rm -rf .build DerivedData
	swift package clean --package-path Packages/Domain
	swift package clean --package-path Packages/Infrastructure
	swift package clean --package-path Packages/Presentation
