nOfParamsNeeded=6

if test $# -lt $nOfParamsNeeded
then
    echo "usage: $0 <line> <lineStatus> <todo_file> <err_file> <ok_file> <ignore_file>"
    exit 1
fi

line=$1
lineStatus=$2

#files
todo_file=$3
err_file=$4
ok_file=$5
ignore_file=$6

#status constants
TO_DO='TO_DO'   #want to do it, yet not done
ERR='ERR'       #want to do it, done, gave error
OK='OK'         #want to do it, done, everything ok
IGNORE='IGNORE' #don't want to do it, not done

if test "$lineStatus" = "$TO_DO"
then
    #line has not been done already done
    #put to todo file
    echo "$line">>$todo_file

elif test "$lineStatus" = "$ERR"
then
    #line has been done with error
    #put to done file
    echo "$line">>$err_file

elif test "$lineStatus" = "$OK"
then
    #line has been done already with success
    #put to done file
    echo "$line">>$ok_file

elif test "$lineStatus" = "$IGNORE"
then
    #line will not be done, not interested on that
    #put to ignore file
    echo "$line">>$ignore_file

else
    echo "ERROR: STATUS NOT EXPECTED"
    echo "line: $line"
    exit 2
fi

exit 0