
.DEFAULT_GOAL := help

DESKTOP_OUT_DIR := build/desktop

COMMON_SOURCES := $(wildcard source/*.odin) .gitmodules
DESKTOP_SOURCES := $(wildcard source/main_desktop/*.odin)
WEB_SOURCES := $(wildcard source/main_web/*.odin)

DESKTOP_TARGET := $(DESKTOP_OUT_DIR)/tictactoetoe
WEB_TARGET :=

.PHONY: run
run: build-desktop  ## Run the Tic Tac Toe game
	./build/desktop/tictactoetoe

.PHONY: update-lib
update-lib:  ## Update the tictactoe Rust library submodule
	git submodule update --remote

$(DESKTOP_TARGET): $(COMMON_SOURCES) $(DESKTOP_SOURCES)
	mkdir -p $(DESKTOP_OUT_DIR)
	odin build source/main_desktop -vet -strict-style -out:$(DESKTOP_OUT_DIR)/tictactoetoe
	cp -R ./assets/ $(DESKTOP_OUT_DIR)/assets/
	ls -lha $(DESKTOP_OUT_DIR)/tictactoetoe

build-desktop: $(DESKTOP_TARGET)  ## Build desktop-only target

build/web: $(COMMON_SOURCES) $(WEB_SOURCES)
	./build_web.sh

build-web: build/web  ## Build web-only target
	@echo Done! To test web build, run: make server

build: build-web build-desktop  ## Build web and desktop targets

.PHONY: server
server: build-web
	(cd build/web && xdg-open http://localhost:8000 && python3 -m http.server 8000)

.PHONY: build
clean: ## Delete temporary build directory
	rm -rf build

release-web: clean build-web
	uvx ghp-import -m "Update web build" build/web
	git push github gh-pages --force

# Implements this pattern for autodocumenting Makefiles:
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
#
# Picks up all comments that start with a ## and are at the end of a target definition line.
.PHONY: help
help:  ## Display this help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
