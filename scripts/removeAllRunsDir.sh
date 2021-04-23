
if test $# -gt 0
then
    dir=$1
else
    echo "usage: $0 <dir>"
    exit 1
fi
cd $dir

ls | egrep "[A-Z]RR[0-9]*" | xargs -d"\n" rm -rf