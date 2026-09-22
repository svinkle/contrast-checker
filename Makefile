.PHONY: all macos test clean

all: macos

macos:
	@$(MAKE) -C macos build

test:
	@$(MAKE) -C macos test

clean:
	@$(MAKE) -C macos clean
	@rm -rf build .cache
