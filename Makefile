.PHONY: all macos windows test clean

all: macos

macos:
	@$(MAKE) -C macos build

windows:
	@$(MAKE) -C windows build

test:
	@$(MAKE) -C macos test

clean:
	@$(MAKE) -C macos clean
	@$(MAKE) -C windows clean 2>/dev/null || true
	@rm -rf build .cache
