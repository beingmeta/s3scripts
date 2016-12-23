PREFIX=/usr
DESTDIR=
AWSCMD		:= $(shell ./dist/getexe aws ${PREFIX}/bin)
AWSROOT		:= $(shell ./dist/getexedir aws ${PREFIX}/bin)
INSTALLROOT 	:= ${AWSROOT}
INSTALLDIR 	:= $(DESTDIR)${INSTALLROOT}
MANDIR 		:= ${INSTALLDIR}/../man/
INSTALL 	:= $(shell which install)
INSTALL_FLAGS	=
CLEAN 		= rm -f
YUMREPO   	= dev:/srv/repo/yum/beingmeta/noarch
YUMHOST   	= dev
YUMUPDATE 	= /srv/repo/scripts/freshyum

VERSION=$(shell dist/gitfullversion)
BASEVERSION=$(shell dist/getnumversion s3scripts)
RELEASE=$(shell dist/gitnumrelease s3scripts)

GPG=$(shell which gpg2 || which gpg || echo gpg)
GPGID=repoman@beingmeta.com
CODENAME=beingmeta

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

# Packaging

dist/debs.setup:
	(git archive --prefix=${VERSION}/                            \
	     -o dist/${VERSION}.tar HEAD) &&                         \
	(cd dist; tar -xf ${VERSION}.tar; rm ${VERSION}.tar) &&      \
	(cd dist; mv ${VERSION}/dist/debian ${VERSION}/debian) &&    \
	(dist/gitchangelog s3scripts stable                          \
	  < dist/debian/changelog                                    \
          > dist/${VERSION}/debian/changelog;) &&                    \
	touch $@;

dist/debs.built: dist/debs.setup
	(cd dist/${VERSION};                                         \
	 dpkg-buildpackage -A -us -uc -sa -rfakeroot) &&             \
	touch $@;

dist/debs.signed: dist/debs.built
	(cd dist; debsign --re-sign -k${GPGID} s3scripts_*_all.changes) && \
	touch $@;

debian debs dpkgs: dist/debs.signed

dist/debs.uploaded: dist/debs.signed
	cd dist; for change in *.changes; do \
	  dupload -c --nomail --to ${CODENAME} $${change} && \
	  rm -f $${change}; \
	done
	touch $@

upload-debs upload-deb: dist/debs.uploaded

update-apt: dist/debs.uploaded
	ssh dev /srv/repo/apt/scripts/getincoming

debclean:
	rm -rf dist/s3scripts-* dist/debs.* dist/*.deb dist/*.changes

debfresh freshdeb newdeb: debclean
	make debian

dist/${VERSION}.tar:
	(git archive --prefix=s3scripts-${BASEVERSION}/ \
			-o dist/${VERSION}.tar HEAD)

${VERSION}.spec: dist/s3scripts.spec.in
	sed ${SPEC_REWRITES} < $< > $@

dist/rpms.built: ${VERSION}.spec dist/${VERSION}.tar
	rpmbuild -ba \
		 --define "_sourcedir ${CWD}/dist" \
	         --define="_rpmdir ${CWD}/dist" \
	         --define="_srcrpmdir ${CWD}/dist" \
	         --define="_gpg_name ${GPGID}" \
	         --define="__gpg ${GPG}" \
	   ${VERSION}.spec
	rpm --resign \
	         --define="_rpmdir ${CWD}" \
	         --define="_srcrpmdir ${CWD}" \
	         --define="_gpg_name ${GPGID}" \
	         --define="__gpg ${GPG}" \
	   dist/s3scripts*.rpm dist/noarch/s3scripts*.rpm
	touch $@;

rpms buildrpms: dist/rpms.built

dist/yum.updated: dist/rpms.built
	scp -r dist/${VERSION}.src.rpm dist/noarch ${YUMREPO}
	ssh ${YUMHOST} ${YUMUPDATE}
	rm -f dist/${VERSION}.src.rpm dist/noarch/*
	touch dist/yum.updated

update-yum: dist/yum.updated

rpmclean:
	rm -rf s3scripts-*.spec dist/s3scripts*.tar dist/rpms.*
	rm -rf dist/*.rpm dist/noarch/*.rpm 

freshrpm freshrpms rpmfresh: rpmclean
	make rpms

.PHONY: debian debs dpkgs debclean debfresh freshdeb newdeb \
	rpms buildrpms rpmclean freshrpms rpmfresh freshrpm \
	upload-debs upload-deb update-apt update-yum
