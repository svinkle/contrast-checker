.PHONY: all build test msi clean icon

all: build

build:
	@powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1

msi:
	@powershell -NoProfile -ExecutionPolicy Bypass -File build.ps1 -BuildMsi

test:
	@dotnet test ContrastChecker.Tests/ContrastChecker.Tests.csproj

icon:
	@python3 scripts/generate_ico.py

clean:
	@rm -rf build ContrastChecker/bin ContrastChecker/obj ContrastChecker.Tests/bin ContrastChecker.Tests/obj ContrastChecker.Installer/bin ContrastChecker.Installer/obj

