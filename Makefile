# These targets are not files
.PHONY: lint lint-scripts lint-ruby check-format format run publish

STACK ?= heroku-24
FIXTURE ?= test/spec/fixtures/repos/play-2.4.x-scala

# Converts a stack name of `heroku-NN` to its build Docker image tag of `heroku/heroku:NN-build`.
STACK_IMAGE_TAG := heroku/$(subst -,:,$(STACK))-build

lint: lint-scripts check-format lint-ruby

lint-scripts:
	@git ls-files -z --cached --others --exclude-standard 'bin/*' 'etc/*' 'lib/*' | xargs -0 shellcheck --check-sourced --color=always

lint-ruby:
	@bundle exec rubocop

check-format:
	@shfmt -f . | grep -v "vendor/" | grep -v "opt/" | grep -v "test/spec/fixtures/" | xargs shfmt --diff

format:
	@shfmt -f . | grep -v "vendor/" | grep -v "opt/" | grep -v "test/spec/fixtures/" | xargs shfmt --write --list

run:
	@echo "Running buildpack using: STACK=$(STACK) FIXTURE=$(FIXTURE)"
	@docker run --rm -v $(PWD):/src:ro --tmpfs /app --platform linux/amd64 -e "HOME=/app" -e "STACK=$(STACK)" "$(STACK_IMAGE_TAG)" \
		bash -euo pipefail -c '\
			mkdir /tmp/buildpack /tmp/build /tmp/cache /tmp/env; \
			cp -r /src/{bin,lib,opt} /tmp/buildpack; \
			cp -rT /src/$(FIXTURE) /tmp/build; \
			cd /tmp/buildpack; \
			unset $$(printenv | cut -d '=' -f 1 | grep -vE "^(HOME|LANG|PATH|STACK)$$"); \
			echo -e "\n~ Detect:" && ./bin/detect /tmp/build; \
			echo -e "\n~ Compile:" && { ./bin/compile /tmp/build /tmp/cache /tmp/env || COMPILE_FAILED=1; }; \
			echo -e "\n~ Report:" && ./bin/report /tmp/build /tmp/cache /tmp/env; \
			[[ "$${COMPILE_FAILED:-}" == "1" ]] && exit 0; \
			[[ -f /tmp/build/bin/compile ]] && { echo -e "\n~ Compile (Inline Buildpack):" && (source ./export && /tmp/build/bin/compile /tmp/build /tmp/cache /tmp/env); }; \
			echo -e "\n~ Release:" && ./bin/release /tmp/build; \
			echo -e "\nBuild successful!"; \
		'
	@echo

publish:
	@etc/publish.sh
