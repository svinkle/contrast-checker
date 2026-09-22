.PHONY: all macos windows linux test test-macos test-linux clean

all: macos

macos:
	@$(MAKE) -C macos build

windows:
	@$(MAKE) -C windows build

linux:
	@$(MAKE) -C linux flatpak

test:
	@$(MAKE) -C macos test
	@$(MAKE) -C linux test

test-macos:
	@$(MAKE) -C macos test

test-linux:
	@$(MAKE) -C linux test

clean:
	@$(MAKE) -C macos clean
	@$(MAKE) -C windows clean 2>/dev/null || true
	@$(MAKE) -C linux clean 2>/dev/null || true
	@rm -rf build .cache

