.PHONY: all test run check-tools flatpak bundle clean

PYTHON ?= python3

all: test

test:
	@echo "==> Running Linux ColorModel Tests..."
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v
	@echo "==> All Linux ColorModel tests PASSED successfully!"

run:
	@PYTHONPATH=src $(PYTHON) src/contrast_checker.py

check-tools:
	@which flatpak >/dev/null 2>&1 || { echo "\n[Error] 'flatpak' is not installed.\nInstall it using:\n  sudo apt install -y flatpak (Ubuntu/Debian)\n  sudo dnf install -y flatpak (Fedora)\n"; exit 1; }
	@which flatpak-builder >/dev/null 2>&1 || { echo "\n[Error] 'flatpak-builder' is not installed.\nInstall it using:\n  sudo apt install -y flatpak-builder (Ubuntu/Debian)\n  sudo dnf install -y flatpak-builder (Fedora)\n"; exit 1; }

flatpak: check-tools
	@echo "==> Building Flatpak package..."
	flatpak-builder --force-clean --user --install-deps-from=flathub build-dir io.github.svinkle.ContrastChecker.yml

bundle: flatpak
	@echo "==> Creating standalone Flatpak bundle..."
	flatpak-builder --export-only --repo=repo build-dir io.github.svinkle.ContrastChecker.yml
	flatpak build-bundle repo ContrastChecker.flatpak io.github.svinkle.ContrastChecker

clean:
	@rm -rf build-dir .flatpak-builder repo ContrastChecker.flatpak
	@find . -type d -name "__pycache__" -exec rm -rf {} +

