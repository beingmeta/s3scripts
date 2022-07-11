PREFIX=/usr
DESTDIR=
AWSCMD		:= $(shell ./dist/getexe aws ${PREFIX}/bin)
AWSROOT		:= $(shell ./dist/getexedir aws ${PREFIX}/bin)
INSTALLROOT 	:= ${AWSROOT}
INSTALLDIR 	:= $(DESTDIR)${INSTALLROOT}
MANDIR 		:= ${INSTALLDIR}/../man
INSTALL 	:= $(shell which install)
INSTALL_FLAGS	=
CLEAN 		= rm -f

GPG=$(shell which gpg2 || which gpg || echo gpg)
GPGID=repoman@beingmeta.com

CODENAME=setup

SCRIPTS=src/s3checkout src/s3update src/s3commit 	\
	src/s3setroot src/s3setopts src/s3import 	\
	src/s3root src/s3src
INSTALLED=${INSTALLDIR}/s3checkout 	\
	${INSTALLDIR}/s3update 	\
	${INSTALLDIR}/s3commit 	\
	${INSTALLDIR}/s3import	\
	${INSTALLDIR}/s3setroot 	\
	${INSTALLDIR}/s3setopts 	\
	${INSTALLDIR}/s3root 		\
	${INSTALLDIR}/s3src

src/%: src/%.in src/header.sh
	@cat src/header.sh $< > $@
	@chmod a+x $@
	@echo "# (s3scripts/makefile) Generated $@";

${INSTALLDIR}/%: src/%
	@echo Installing $< to $@ using ${INSTALLDIR} and '${DESTDIR}'
	@${INSTALL} ${INSTALLFLAGS} -m 775 $< $@
	@echo Installed $< to $@

# The default

default build scripts: ${SCRIPTS}

.PHONY: build scripts default

# Getting rid of stuff

uninstall:
	rm -f ${INSTALLED}

tidy:
	@${CLEAN} *~ src/*~ docs/*~ docs/ronn/*~ docs/man/*~
	@${CLEAN} docs/man.html/*~ docs/man.html.include/*~
	@${CLEAN} #*# src/#*# docs/#*# docs/ronn/#*# docs/man/#*#
	@${CLEAN} docs/man.html/#*# docs/man.html.include/#*#

clean:
	@${CLEAN} ${SCRIPTS} 
	@${CLEAN} docs/man/*.1 docs/man/*.gz
	@${CLEAN} docs/man.html/*.html docs/man.html.include/*.html

.PHONY:  uninstall clean tidy

# Documentation

docs:
	@cd docs; make

manpages:
	@cd docs; make man.gz

.PHONY: docs install-docs

# Installation

install: ${INSTALLDIR} ${INSTALLED} install-docs

${INSTALLDIR}:
	@${INSTALL} -d ${INSTALLFLAGS} $@

install-docs: ${INSTALLDIR} docs manpages
	@${INSTALL} -d ${MANDIR}/man1
	@${INSTALL} docs/man/*.1.gz ${MANDIR}/man1

install-man install-manpages: manpages
	@${INSTALL} docs/man/*.1.gz ${MANDIR}/man1

.PHONY: install install-docs install-man install-manpages 

