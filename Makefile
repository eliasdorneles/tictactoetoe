
.DEFAULT_GOAL := help

.PHONY: run
run: build-desktop  ## Run the Tic Tac Toe game
	./build/desktop/tictactoetoe

.PHONY: update-lib
update-lib:  ## Update the tictactoe Rust library submodule
	git submodule update --remote

.PHONY: server
server:
	(cd build/web && xdg-open http://localhost:8000 && python3 -m http.server 8000)

.PHONY: build-desktop
build-desktop:
	./build_desktop.sh tictactoetoe

.PHONY: build-web
build-web:
	./build_web.sh

.PHONY: build
build: build-web build-desktop  ## Build web and desktop targets

release-web: build-web
	uvx ghp-import -m "Update web build" build/web
	git push github gh-pages --force

# Implements this pattern for autodocumenting Makefiles:
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
#
# Picks up all comments that start with a ## and are at the end of a target definition line.
.PHONY: help
help:  ## Display command usage
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
