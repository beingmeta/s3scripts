RONN_MANUAL       = S3Scripts
RONN_ORGANIZATION = beingmeta.com

PAGES=s3checkout.1 s3update.1 s3commit.1 s3src.1 s3root.1 s3setroot.1 s3setopts.1

# We end things with \c to avoid breaking things up with newlines
MANPAGES=$(shell for page in ${PAGES}; do echo man/$${page}; done )
MANGZ=$(shell for page in ${PAGES}; do echo man/$${page}.gz; done )
HTMLPAGES=$(shell for page in ${PAGES}; do echo man.html/$${page}.html; done )
HTMLINCLUDEPAGES=$(shell for page in ${PAGES}; do echo man.html.include/$${page}.html; done )

man/%: ronn/%.ronn
	ronn --roff < $< > $@
man.html/%.html: ronn/%.ronn
	ronn --html < $< > $@
man.html.include/%.html: ronn/%.ronn
	ronn --fragment < $< > $@
man/%.gz: man/%
	gzip -c $< > $@

all: man man.html man.html.include

man manpages: ${MANPAGES}

man.gz: ${MANGZ}

html htmlpages man.html: ${HTMLPAGES}

htmlinclude man.html.include: ${HTMLINCLUDEPAGES}

install:

clean:
	rm -f man.html/*.html man.html.include/*.html

.PHONY: mangz man manpages man.html man.html.include

