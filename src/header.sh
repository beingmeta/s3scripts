#!/bin/sh

DEFAULT_AWS=`which aws`;
AWS=${AWS:-${DEFAULT_AWS}}

echo AWS=${AWS}

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
    output=
    scan=
    if test $# -gt 1; then
	scan=$1
	output=$2
    elif test $# -gt 0; then
	scan=$1
    else
	scan=`pwd`
    fi;
    if test "${scan}" == "."; then
	scan=`pwd`;
    elif test "${scan}" == ".."; then
	scan=`pwd`;
	scan=`dirname ${scan}`
    fi
    # echo scan=${scan}
    scan=`getrealpath ${scan}`
    if test ! -d ${scan}; then
	base=`basename ${scan}`
	relpath="${base}"
	scan=`dirname ${scan}`
    else
	relpath="";
    fi;
    while ( test ! -z "${scan}" && test ! -f .s3root ); do
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
	if test -z "${output}"; then
	    printf "%s\\n" "${s3root}/${relpath}";
	else
	    printf "%s\\n" "${s3root}/${relpath}" > ${output};
	    retval=0;
	fi
    else
	retval=1
    fi;
}

gets3root ( ) {
    output=
    dir=
    if test $# -gt 1; then
	dir=$1
	output=$2
    else
	dir=$1
    fi;
    dir=`getrealpath ${dir}`;
    if test ! -d ${dir}; then
	dir=`dirname $dir`;
    fi;
    relpath=""
    while ( test ! -z "${dir}" && test ! -f .s3root ); do
	base=`basename ${dir}`;
	relpath="${base}/${relpath}";
	dir=`dirname ${dir}`;
	done;
    if test -f ${dir}/.s3root; then
	if test -z "${output}"; then
	    printf "%s/" "${dir}";
	else
	    printf "%s/" "${dir}" > ${output};
	fi;
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

save2s3 ( ) {
    path=$1;
    retval=1;
    if test -f ${path}; then
	fullpath=`getrealpath ${path}`;
	src=`gets3src ${fullpath}`;
	opts=`gets3opts ${fullpath}`;
        name=`basename ${fullpath}`
        envopts=${S3SCRIPTOPTS}
	if test -z "${src}"; then
	    echo "Warning: the path ${path} was not checked out of S3!";
	   retval=1;
	elif ${AWS} s3 cp ${envopts} ${opts} ${fullpath} ${src}; then
	   retval=0;
	else
	   retval=1;
	fi;
    elif test -d ${path}; then
	 echo "The path ${path} is a directory";
    else
	echo "The path ${path} does not exist";
    fi;
}

###  Local variables: ***
###  compile-command: "if test -f ../makefile; then cd ..; make scripts; fi;" ***
###  indent-tabs-mode: nil ***
###  End: ***
