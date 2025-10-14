
.DEFAULT_GOAL := help

.PHONY: run
run:  ## Run the Tic Tac Toe game
	odin run game_tictactoetoe.odin -file

.PHONY: tictactoetoe
tictactoetoe: game_tictactoetoe.odin  ## Build the Tic Tac Toe game executable
	odin build game_tictactoetoe.odin -file -out:tictactoetoe

# Implements this pattern for autodocumenting Makefiles:
# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
#
# Picks up all comments that start with a ## and are at the end of a target definition line.
.PHONY: help
help:  ## Display command usage
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
