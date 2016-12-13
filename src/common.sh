gets3root ( ) {
    if test $# -eq 0; then
	dir=`pwd`;
    elif test -z $1; then
	 dir=`pwd`;
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
	s3root=`cat ${dir}/.s3root`;
	echo "${s3root}/${relpath}/";
	retval=1;
    else
	retval=0;
    fi;
}


