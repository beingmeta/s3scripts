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
    fi
    exec ${AWS} $*;
}

mkpath ( ) {
    dir=$1;
    path=$2;
    if echo ${dir} | grep "/$" 2>&1 > /dev/null; then
        echo ${dir}${path};
    else
        echo ${dir}/${path};
    fi;
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
	scan=${wd};
    elif test $# -gt 1; then
	scan=$1
    else
	scan=$1
    fi;
    if test "${scan}" == "."; then
	scan=${wd};
    elif test "${scan}" == ".."; then
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
	    relpath="${scan}";
        else
	    relpath="${scan}/${relpath}";
        fi;
	scan=`dirname ${scan}`
    done;
    if test -f ${scan}/.s3root; then
	s3root=`cat ${scan}/.s3root`
        savepath=`mkpath ${s3root} ${relpath}`
	if test -z "${output}"; then
	    printf "%s\\n" "${savepath}";
	else
	    printf "%s\\n" "${savepath}" > ${output};
	    retval=0;
	fi
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
    if test "${scan}" == "."; then
	scan=${wd};
    elif test "${scan}" == ".."; then
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
	printf "%s/" "${dir}" > ${output};
	retval=0;
    else
	retval=1;
    fi;
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
