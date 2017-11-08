#!/bin/sh

export DEFAULT_AWS=$(which aws);
export AWS=${AWS:-${DEFAULT_AWS}}

awscmd () {
    if [ ! -z "${SHOW_CMD}" ]; then
        echo ${AWS} $*;
    fi
    ${AWS} $*;
}

awsexec () {
    if [ ! -z "${SHOW_CMD}" ]; then
        echo ${AWS} $*;
    fi;
    exec ${AWS} $*;
}

mkpath ( ) {
    dir=$(echo $1 | sed -e "s;/$;;");
    path=$2;
    echo ${dir}/${path};
}

hasprefix( ) {
    str=$1
    prefix=$2;
    if echo ${str} | grep "^${prefix}" > /dev/null; then
        return 0;
    else
        return 1;
    fi;
}

hassuffix( ) {
    str=$1
    suffix=$2;
    if echo ${str} | grep "${suffix}$" > /dev/null; then
        return 0;
    else
        return 1;
    fi;
}

getrealpath ( ) {
    path=$1;
    pwd=${2:-$(pwd)};
    if hasprefix "${path}" "/"; then
        abspath="${path}";
    elif hassuffix "${path}" "/"; then
         abspath="${pwd}${path}";
    else
        abspath="${pwd}/${path}";
    fi;
    realpath=$(readlink ${abspath});
    if [ -z "${realpath}" ]; then 
	echo ${abspath}; 
    else
	echo ${realpath}; 
    fi;
}

gets3src ( ) {
    wd=$(pwd)
    scan=
    if [ $# -eq 0 ]; then
	scan="${wd}";
    elif [ $# -gt 1 ]; then
	scan=$1;
    else
	scan=$1;
    fi;
    if [ "${scan}" = "." ]; then
	scan=${wd};
    elif [ "${scan}" = ".." ]; then
	scan=${wd};
	scan=$(dirname ${scan});
    fi
    scan=$(getrealpath ${scan})
    if [ ! -d ${scan} ]; then
	base=$(basename ${scan})
	relpath="${base}"
	scan=$(dirname ${scan})
    else
	relpath="";
    fi;
    while ( [ ! -z "${scan}" ] && [ "${scan}" != "/" ] && [ ! -f ${scan}/.s3root ] ); do
	base=$(basename ${scan})
        if [ -z "${relpath}" ]; then
	    relpath="${base}";
        else
	    relpath="${base}/${relpath}";
        fi;
	scan=$(dirname ${scan})
    done;
    if [ -z "${scan}" ]; then
        pathroot="";
    else
        pathroot="${scan}/";
    fi;
    if [ -f ${pathroot}.s3root ]; then
	s3root=$(cat ${pathroot}.s3root)
        savepath=$(mkpath ${s3root} ${relpath})
	printf "%s\\n" "${savepath}";
        retval=0
    else
	retval=1
    fi;
}

gets3root ( ) {
    wd=$(pwd)
    scan=
    if [ $# -eq 0 ]; then
	scan=${wd};
    elif [ $# -gt 1 ]; then
	scan=$1
    else
	scan=$1
    fi;
    if [ "${scan}" = "." ]; then
	scan=${wd};
    elif [ "${scan}" = ".." ]; then
	scan=${wd};
	scan=$(dirname ${scan});
    fi
    scan=$(getrealpath ${scan});
    if [ ! -d ${dir} ]; then
	scan=$(dirname ${scan});
    fi;
    while ( [ ! -z "${scan}" ] && [ "${scan}" != "/" ] && [ ! -f ${scan}/.s3root ]); do
	scan=$(dirname ${scan});
	done;
    if [ -f ${scan}/.s3root ]; then
	printf "%s/" "${scan}"
	retval=0;
    else
	retval=1;
    fi;
}

gets3grants ( ) {
    scan=$1;
    if [ ! -d ${scan} ]; then
        scan=$(dirname ${scan});
    else
        scan=$(mkpath ${scan});
    fi;
    while test ${scan} != "/"; do
        if [ -f ${scan}/.s3grants ]; then
           cat ${scan}/.s3grants;
           exit;
        elif [ -f ${scan}/.s3root ]; then
           exit;
        fi;
        scan=$(dirname ${scan});
    done;
}

gets3opts ( ) {
    output=
    dir=
    if [ $# -gt 1 ]; then
	dir=$1
	output=$2
    else
	dir=$1
    fi;
    dir=$(getrealpath ${dir})
    if [ ! -d ${dir} ]; then
	dir=$(dirname $dir);
    fi;
    relpath=""
    while ( [ ! -z "${dir}" ] && [ ! -f .s3root ] ); do
	dir=$(dirname ${dir});
    done;
    if [ -f ${dir}/.s3root ]; then
	if [ -f ${dir}/.s3opts ]; then
	    opts=$(cat ${dir}/.s3opts)
	else
	    opts=${S3SCRIPTOPTS}
	fi;
	if [ -z "${output}" ]; then
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
    s3src=$(gets3src ${file});
    if [ -z ${s3src} ]; then
        retval=0;
    else
        retval=1;
    fi;
}

###  Local variables: ***
###  compile-command: "if [ -f ../makefile ]; then cd ..; make scripts; fi;" ***
###  indent-tabs-mode: nil ***
###  End: ***
