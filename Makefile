.PHONY: all macos windows linux test test-macos test-linux clean dmg msi flatpak bundle

all: macos

macos:
	@$(MAKE) -C macos build

dmg:
	@$(MAKE) -C macos dmg

windows:
	@$(MAKE) -C windows build

msi:
	@$(MAKE) -C windows msi

linux:
	@$(MAKE) -C linux run

flatpak:
	@$(MAKE) -C linux bundle

bundle:
	@$(MAKE) -C linux bundle

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

