#!/bin/sh

DEFAULT_AWS=`which aws`;
SHOW_CMD=
AWS=${AWS:-${DEFAULT_AWS}}

awscmd () {
    if test ! -z "${SHOW_CMD}"; then
        echo ${AWS} $*;
    fi
    ${AWS} $*;
}

awsexec () {
    if test ! -z "${SHOW_CMD}"; then
        echo ${AWS} $*;
    fi;
    exec ${AWS} $*;
}

mkpath ( ) {
    dir=`echo $1 | sed -e "s;/$;;"`;
    path=$2;
    echo ${dir}/${path};
}

getrealpath ( ) {
    path=$1;
    pwd=${2:-`pwd`};
    abspath=`echo ${path} | sed -e "s;\(^[^/]\);${pwd}/\1;" | sed -e "s;/./;/;" | sed -e "s;/[^/]+/../;/;"`
    realpath=`readlink ${abspath}`;
    if test -z "${realpath}"; then 
	echo ${abspath}; 
    else
	echo ${realpath}; 
    fi;
}

gets3src ( ) {
    wd=`pwd`
    scan=
    if test $# -eq 0; then
	scan="${wd}";
    elif test $# -gt 1; then
	scan=$1;
    else
	scan=$1;
    fi;
    if test "${scan}" = "."; then
	scan=${wd};
    elif test "${scan}" = ".."; then
	scan=${wd};
	scan=`dirname ${scan}`;
    fi
    scan=`getrealpath ${scan}`
    if test ! -d ${scan}; then
	base=`basename ${scan}`
	relpath="${base}"
	scan=`dirname ${scan}`
    else
	relpath="";
    fi;
    while ( test ! -z "${scan}" && test "${scan}" != "/" && test ! -f ${scan}/.s3root ); do
	base=`basename ${scan}`
        if test -z "${relpath}"; then
	    relpath="${base}";
        else
	    relpath="${base}/${relpath}";
        fi;
	scan=`dirname ${scan}`
    done;
    if test -f ${scan}/.s3root; then
	s3root=`cat ${scan}/.s3root`
        savepath=`mkpath ${s3root} ${relpath}`
	printf "%s\\n" "${savepath}";
        retval=0
    else
	retval=1
    fi;
}

gets3root ( ) {
    wd=`pwd`
    scan=
    if test $# -eq 0; then
	scan=${wd};
    elif test $# -gt 1; then
	scan=$1
    else
	scan=$1
    fi;
    if test "${scan}" = "."; then
	scan=${wd};
    elif test "${scan}" = ".."; then
	scan=${wd};
	scan=`dirname ${scan}`;
    fi
    scan=`getrealpath ${scan}`;
    if test ! -d ${dir}; then
	scan=`dirname ${scan}`;
    fi;
    while ( test ! -z "${scan}" && 
                test "${scan}" != "/" && 
                test ! -f .s3root ); do
	scan=`dirname ${scan}`;
	done;
    if test -f ${scan}/.s3root; then
	printf "%s/" "${dir}"
	retval=0;
    else
	retval=1;
    fi;
}

gets3grants ( ) {
    scan=$1;
    if test ! -d ${scan}; then
        scan=`dirname ${scan}`;
    else
        scan=`mkpath ${scan}`;
    fi;
    while test ${scan} != "/"; do
        if test -f ${scan}/.s3grants; then
           cat ${scan}/.s3grants;
           exit;
        elif test -f ${scan}/.s3root; then
           exit;
        fi;
        scan=`dirname ${scan}`;
    done;
}

gets3opts ( ) {
    output=
    dir=
    if test $# -gt 1; then
	dir=$1
	output=$2
    else
	dir=$1
    fi;
    dir=`getrealpath ${dir}`
    if test ! -d ${dir}; then
	dir=`dirname $dir`;
    fi;
    relpath=""
    while ( test ! -z "${dir}" && test ! -f .s3root ); do
	dir=`dirname ${dir}`;
    done;
    if test -f ${dir}/.s3root; then
	if test -f ${dir}/.s3opts; then
	    opts=`cat ${dir}/.s3opts`
	else
	    opts=${S3SCRIPTOPTS}
	fi;
	if test -z "${output}"; then
	    printf "%s" "${opts}";
	else
	    printf "%s" "${opts}" > ${output};
	fi;
	retval=0;
    else
	retval=1;
    fi;
}

s3check ( ) {
    file=$1;
    s3src=`gets3src ${file}`;
    if test -z ${s3src}; then
        retval=0;
    else
        retval=1;
    fi;
}

###  Local variables: ***
###  compile-command: "if test -f ../makefile; then cd ..; make scripts; fi;" ***
###  indent-tabs-mode: nil ***
###  End: ***
