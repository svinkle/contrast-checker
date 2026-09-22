.PHONY: all test run flatpak bundle clean

PYTHON ?= python3

all: test

test:
	@echo "==> Running Linux ColorModel Tests..."
	@$(PYTHON) -m unittest discover -s tests -p "test_*.py" -v
	@echo "==> All Linux ColorModel tests PASSED successfully!"

run:
	@PYTHONPATH=src $(PYTHON) src/contrast_checker.py

flatpak:
	@echo "==> Building Flatpak package..."
	flatpak-builder --force-clean --user --install-deps-from=flathub build-dir io.github.svinkle.ContrastChecker.yml

bundle: flatpak
	@echo "==> Creating standalone Flatpak bundle..."
	flatpak-builder --export-only --repo=repo build-dir io.github.svinkle.ContrastChecker.yml
	flatpak build-bundle repo ContrastChecker.flatpak io.github.svinkle.ContrastChecker

clean:
	@rm -rf build-dir .flatpak-builder repo ContrastChecker.flatpak
	@find . -type d -name "__pycache__" -exec rm -rf {} +
