SHELL = /bin/sh
SHELLCHECK = shellcheck
SHELLCHECK_OPTS = -x

PREFIX=/usr/local
BINDIR=$(PREFIX)/bin

.PHONY: install
install: k3rn3l.sh
	install $< $(DESTDIR)$(BINDIR)/k3rn3l

.PHONY: shellcheck
shellcheck: k3rn3l.sh
	$(SHELLCHECK) $(SHELLCHECK_OPTS) $<

.PHONY: test
test:
	bats test

.PHONY: coverage
coverage:
	kcov --include-path=. coverage bats test/

.PHONY: clean
clean:
	rm -rf ./coverage
