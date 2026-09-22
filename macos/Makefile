.PHONY: all build run test clean install dmg

all: build

build:
	@chmod +x build.sh
	@./build.sh

dmg: build
	@chmod +x create_dmg.sh
	@./create_dmg.sh

test:
	@mkdir -p build .cache
	@swiftc -parse-as-library -module-cache-path ./.cache Sources/ColorModel.swift Tests/run_tests.swift -o build/run_tests
	@./build/run_tests

run: build
	@open build/ContrastChecker.app

clean:
	@rm -rf build .cache

install: build
	@echo "==> Installing ContrastChecker.app to /Applications..."
	@rm -rf /Applications/ContrastChecker.app
	@cp -R build/ContrastChecker.app /Applications/
	@echo "==> Installed ContrastChecker.app to /Applications"
