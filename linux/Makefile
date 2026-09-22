.PHONY: all test run install-user check-tools setup-flathub flatpak bundle clean

PYTHON ?= python3

all: test

test:
	@echo "==> Running Linux ColorModel Tests..."
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v
	@echo "==> All Linux ColorModel tests PASSED successfully!"

install-user:
	@echo "==> Registering desktop launcher and icons in ~/.local/share..."
	@mkdir -p $(HOME)/.local/share/applications
	@mkdir -p $(HOME)/.local/share/pixmaps
	@for size in 16 24 32 48 64 96 128 256 512; do \
		mkdir -p $(HOME)/.local/share/icons/hicolor/$${size}x$${size}/apps; \
		cp icons/$${size}x$${size}/apps/io.github.svinkle.ContrastChecker.png $(HOME)/.local/share/icons/hicolor/$${size}x$${size}/apps/io.github.svinkle.ContrastChecker.png 2>/dev/null || true; \
	done
	@cp icons/256x256/apps/io.github.svinkle.ContrastChecker.png $(HOME)/.local/share/pixmaps/io.github.svinkle.ContrastChecker.png 2>/dev/null || true
	@sed -e 's|Exec=contrast-checker|Exec=$(CURDIR)/src/contrast_checker.py|g' \
	     -e 's|Icon=io.github.svinkle.ContrastChecker|Icon=$(HOME)/.local/share/icons/hicolor/256x256/apps/io.github.svinkle.ContrastChecker.png|g' \
	     io.github.svinkle.ContrastChecker.desktop > $(HOME)/.local/share/applications/io.github.svinkle.ContrastChecker.desktop
	@chmod +x $(HOME)/.local/share/applications/io.github.svinkle.ContrastChecker.desktop
	@update-desktop-database $(HOME)/.local/share/applications 2>/dev/null || true
	@gtk-update-icon-cache -f -t $(HOME)/.local/share/icons/hicolor 2>/dev/null || true
	@echo "==> Desktop integration complete."

run: install-user
	@PYTHONPATH=src $(PYTHON) src/contrast_checker.py

check-tools:
	@which flatpak >/dev/null 2>&1 || { echo "\n[Error] 'flatpak' is not installed.\nInstall it using:\n  sudo apt install -y flatpak (Ubuntu/Debian)\n  sudo dnf install -y flatpak (Fedora)\n"; exit 1; }
	@which flatpak-builder >/dev/null 2>&1 || { echo "\n[Error] 'flatpak-builder' is not installed.\nInstall it using:\n  sudo apt install -y flatpak-builder (Ubuntu/Debian)\n  sudo dnf install -y flatpak-builder (Fedora)\n"; exit 1; }

setup-flathub: check-tools
	@echo "==> Ensuring user Flathub repository is configured..."
	@flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
	@flatpak --user update --appstream 2>/dev/null || true

flatpak: check-tools setup-flathub
	@echo "==> Building Flatpak package..."
	flatpak-builder --force-clean --user --install-deps-from=flathub build-dir io.github.svinkle.ContrastChecker.yml

bundle: flatpak
	@echo "==> Creating standalone Flatpak bundle..."
	flatpak-builder --export-only --repo=repo build-dir io.github.svinkle.ContrastChecker.yml
	flatpak build-bundle repo ContrastChecker.flatpak io.github.svinkle.ContrastChecker

clean:
	@rm -rf build-dir .flatpak-builder repo ContrastChecker.flatpak
	@find . -type d -name "__pycache__" -exec rm -rf {} +

