.PHONY: all run serve test icons clean

PORT ?= 8000

all: test

run: serve

serve:
	@echo "Serving Contrast Checker PWA at http://localhost:$(PORT)"
	@python3 -m http.server $(PORT)

test:
	@node tests/test_color_model.js

icons:
	@python3 scripts/generate_icons.py

clean:
	@rm -rf .cache
