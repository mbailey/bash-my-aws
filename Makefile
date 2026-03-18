.PHONY: build build-verbose test run_tests check clean install-hooks

build:
	@./scripts/build > /dev/null 2>&1
	@echo "Build complete."
	@echo "  Functions: $$(wc -l < functions | tr -d ' ')"
	@echo "  Aliases:   $$(grep -c '^alias ' aliases)"
	@if ! git diff --quiet aliases functions bash_completion.sh 2>/dev/null; then \
		echo ""; \
		echo "Changed files:"; \
		git diff --stat aliases functions bash_completion.sh; \
	fi

build-verbose:
	./scripts/build

test: run_tests

run_tests:
	'./test/shared-spec.sh'
	'./test/stack-spec.sh'

check:
	@echo "Checking if generated files are up to date..."
	@./scripts/build > /dev/null 2>&1
	@if git diff --quiet aliases functions bash_completion.sh; then \
		echo "✓ Generated files are up to date"; \
	else \
		echo "✗ Generated files are out of date. Run 'make build' to update."; \
		git diff --stat aliases functions bash_completion.sh; \
		exit 1; \
	fi

clean:
	@echo "Restoring generated files to git HEAD..."
	git checkout -- aliases functions bash_completion.sh

install-hooks:
	@echo "Installing git hooks..."
	ln -sf ../../scripts/hooks/pre-push .git/hooks/pre-push
	@echo "✓ pre-push hook installed"
