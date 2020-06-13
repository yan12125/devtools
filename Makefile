V=20200407

PREFIX = /usr/local
MANDIR = $(PREFIX)/share/man

IN_PROGS = \
	git-archrelease \
	git-commitpkg

BINPROGS = \
	$(IN_PROGS)

COMMITPKG_LINKS = \
	git-extrapkg \
	git-communitypkg

all: $(BINPROGS)

edit = sed -e "s|@pkgdatadir[@]|$(PREFIX)/share/devtools|g"

%: %.in Makefile lib/common.sh
	@echo "GEN $@"
	@$(RM) "$@"
	@{ echo -n 'm4_changequote([[[,]]])'; cat $@.in; } | m4 -P | $(edit) >$@
	@chmod a-w "$@"
	@chmod +x "$@"
	@bash -O extglob -n "$@"

$(MANS): doc/asciidoc.conf doc/footer.asciidoc

doc/%: doc/%.asciidoc
	a2x --no-xmllint --asciidoc-opts="-f doc/asciidoc.conf" -d manpage -f manpage -D doc $<

clean:
	rm -f $(IN_PROGS) bash_completion zsh_completion $(MANS)

install:
	install -dm0755 $(DESTDIR)$(PREFIX)/bin
	install -m0755 ${BINPROGS} $(DESTDIR)$(PREFIX)/bin
	for l in ${COMMITPKG_LINKS}; do ln -sf git-commitpkg $(DESTDIR)$(PREFIX)/bin/$$l; done

uninstall:
	for f in ${BINPROGS}; do rm -f $(DESTDIR)$(PREFIX)/bin/$$f; done
	for l in ${COMMITPKG_LINKS}; do rm -f $(DESTDIR)$(PREFIX)/bin/$$l; done

TODAY=$(shell date +"%Y%m%d")
tag:
	@sed -E "s|^V=[0-9]{8}|V=$(TODAY)|" -i Makefile
	@git commit --gpg-sign --message "Version $(TODAY)" Makefile
	@git tag --sign --message "Version $(TODAY)" $(TODAY)

dist:
	git archive --format=tar --prefix=devtools-$(V)/ $(V) | gzip -9 > devtools-$(V).tar.gz
	gpg --detach-sign --use-agent devtools-$(V).tar.gz

upload:
	scp devtools-$(V).tar.gz devtools-$(V).tar.gz.sig repos.archlinux.org:/srv/ftp/other/devtools/

check: $(BINPROGS) bash_completion makepkg-x86_64.conf PKGBUILD.proto
	shellcheck $^

.PHONY: all clean install uninstall dist upload check tag
.DELETE_ON_ERROR:
