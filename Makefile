# These targets are not files
.PHONY: lint-scripts

lint-scripts:
	@git ls-files -z --cached --others --exclude-standard 'bin/*' 'etc/*' 'lib/*.sh' 'opt/*.sh' | grep -zv buildpack-stdlib-v7.sh | xargs -0 shellcheck --check-sourced --color=always
