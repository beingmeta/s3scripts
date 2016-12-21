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

# Packaging

dist/debs.setup:
	(git archive --prefix=${VERSION}/                            \
	     -o dist/${VERSION}.tar HEAD) &&                         \
	(cd dist; tar -xf ${VERSION}.tar; rm ${VERSION}.tar) &&      \
	(cd dist; mv ${VERSION}/dist/debian ${VERSION}/debian) &&    \
	(etc/gitchangelog upsource stable                            \
	  < dist/debian/changelog                                    \
          > dist/${VERSION}/debian/changelog;) &&                    \
	touch $@;

dist/debs.built: dist/debs.setup
	(cd dist/${VERSION};                                         \
	 dpkg-buildpackage -A -us -uc -sa -rfakeroot) &&             \
	touch $@;

dist/debs.signed: dist/debs.built
	(cd dist; debsign --re-sign -k${GPGID} upsource_*_all.changes) && \
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
	rm -rf dist/upsource-* dist/debs.* dist/*.deb dist/*.changes

debfresh freshdeb newdeb: debclean
	make debian

dist/${VERSION}.tar:
	(git archive --prefix=upsource-${BASEVERSION}/ -o dist/${VERSION}.tar HEAD)

${VERSION}.spec: dist/upsource.spec.in
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
	   dist/upsource*.rpm dist/noarch/upsource*.rpm
	touch $@;

rpms buildrpms: dist/rpms.built

dist/yum.updated: dist/rpms.built
	scp -r dist/${VERSION}.src.rpm dist/noarch ${YUMREPO}
	ssh ${YUMHOST} ${YUMUPDATE}
	rm -f dist/${VERSION}.src.rpm dist/noarch/*
	touch dist/yum.updated

update-yum: dist/yum.updated

rpmclean:
	rm -rf upsource-*.spec dist/upsource*.tar dist/rpms.*
	rm -rf dist/*.rpm dist/noarch/*.rpm 

freshrpm freshrpms rpmfresh: rpmclean
	make rpms

.PHONY: debian debs dpkgs debclean debfresh freshdeb newdeb \
	rpms buildrpms rpmclean freshrpms rpmfresh freshrpm \
	upload-debs upload-deb update-apt update-yum
