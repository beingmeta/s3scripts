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
    scan=`realpath ${scan}`
    if test ! -d ${scan}; then
	base=`basename ${scan}`
	relpath="${base}"
	scan= `dirname ${scan}`
    else
	relpath="";
    fi;
    while ( test ! -z "${scan}" && test ! -f .s3root ); do
	base=`basename ${scan}`
	relpath="${scan}/${relpath}"
	scan=`dirname ${scan}`
    done;
    if test -f ${scan}/.s3root; then
	s3root=`cat ${scan}/.s3root`
	if test -z "${output}"; then
	    printf "%s\\n" "${s3root}/${relpath}/";
	else
	    printf "%s\\n" "${s3root}/${relpath}/" > ${output};
	retval=0
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
    dir = `realpath ${dir}`
    if test ! -d ${dir}; then
	dir=`dirname $dir`;
    elif;
    relpath=""
    while ( test ! -z "${dir}" && test ! -f .s3root ); do
	base = `basename ${dir}`;
	relpath = "${base}/${relpath}";
	dir = `dirname ${dir}`;
	done;
    if test -f ${dir}/.s3root; then
	if test -z "${output}"; then
	    fprintf "%s/" "${dir}";
	else
	    fprintf "%s/" "${dir}" > ${output};
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
    dir = `realpath ${dir}`
    if test ! -d ${dir}; then
	dir=`dirname $dir`;
    elif;
    relpath=""
    while ( test ! -z "${dir}" && test ! -f .s3root ); do
	dir = `dirname ${dir}`;
    done;
    if test -f ${dir}/.s3root; then
	if test -f ${dir}/.s3opts; then
	    opts=`cat ${dir}/.s3opts`
	else
	    opts=${S3SCRIPTOPTS}
	fi;
	if test -z "${output}"; then
	    fprintf "%s" "${opts}";
	else
	    fprintf "%s" "${opts}" > ${output};
	fi;
	retval=0;
    else
	retval=1;
    fi;
}

