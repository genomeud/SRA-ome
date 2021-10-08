
file_sql=$1

sql_runner='./run_sql.sh'
user='postgres'
db='sra_analysis'

pg_log_file=${file_sql}.log
errors_log_file=${file_sql}.errors.log

echo -n >$pg_log_file
echo -n >$errors_log_file

$sql_runner $file_sql $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $errors_log_file >&2)