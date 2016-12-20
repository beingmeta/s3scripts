PREFIX=/usr
AWSCMD := $(shell which aws || echo ${PREFIX}/bin/aws)
INSTALLDIR := $(shell dirname ${AWSCMD})
INSTALL := $(shell which install)
INSTALL_FLAGS=
MANDIR := ${INSTALLDIR}/../man/
CLEAN = rm -f

SCRIPTS=src/s3checkout src/s3update src/s3commit \
	src/s3setroot src/s3setopts src/s3import \
	src/s3root src/s3src
INSTALLED=${INSTALLDIR}/s3checkout ${INSTALLDIR}/s3update ${INSTALLDIR}/s3commit	\
	${INSTALLDIR}/s3setroot ${INSTALLDIR}/s3setopts ${INSTALLDIR}/s3import  	\
	${INSTALLDIR}/s3root ${INSTALLDIR}/s3src 

src/%: src/%.in src/header.sh
	@cat src/header.sh $< > $@
	@chmod a+x $@

${INSTALLDIR}/%: src/%
	@${INSTALL} ${INSTALLFLAGS} -m 775 $< $@
	@echo Installing $< to $@

build scripts: ${SCRIPTS}

install: ${INSTALLED}

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

docs:
	@cd docs; make

install-docs: docs man.gz
	@${INSTALL} -d ${MANDIR}/man1
	@${INSTALL} docs/man/*.1.gz ${MANDIR}/man1

manpages:
	@cd docs; make man.gz

install-man install-manpages: manpages
	@${INSTALL} docs/man/*.1.gz ${MANDIR}/man1

.PHONY: build scripts install clean docs install-docs
