SHELL = /bin/sh
SHELLCHECK = shellcheck
SHELLCHECK_OPTS = -x

prefix=/usr/local
bindir=$(prefix)/bin

.PHONY: install
install: k3rn3l.sh
	install $< $(DESTDIR)$(bindir)/k3rn3l

.PHONY: shellcheck
shellcheck: k3rn3l.sh
	$(SHELLCHECK) $(SHELLCHECK_OPTS) $<
