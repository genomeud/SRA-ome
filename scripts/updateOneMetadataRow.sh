nOfParamsNeeded=5

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <line> <lineStatus> <todo_file> <err_file> <ok_file>"
    exit 1
fi

line=$1
lineStatus=$2
todo_file=$3
err_file=$4
ok_file=$5

todo='NO'
err='ERR'
ok='OK'

if test "$lineStatus" = "$todo"
then
    #line has not been done already done
    #put to todo file
    echo "$line">>$todo_file
elif test "$lineStatus" = "$err"
then
    #line has been done with error
    #put to done file
    echo "$line">>$err_file
elif test "$lineStatus" = "$ok"
then
    #line has been done already with success
    #put to done file
    echo "$line">>$ok_file
else
    echo "ERROR: STATUS NOT EXPECTED"
    echo "line: $line"
    exit 2
fi

exit 0