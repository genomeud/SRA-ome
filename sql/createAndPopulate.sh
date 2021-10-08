#set -x

sql_runner='./run_sql.sh'

user='postgres'
db='postgres'
main_folder='.'
population_folder=$main_folder'/4_population'
functions_folder=$main_folder'/5_functions'

pg_log_file='log_postgres.log'
commands_errors_log_file='log_commands_and_errors.log'

echo -n >$pg_log_file
echo -n >$commands_errors_log_file

echo $(date) >>$commands_errors_log_file

#0)
echo "deleting db..." | tee -a $commands_errors_log_file
delete_db_file=$main_folder'/0_delete.sql'
$sql_runner $delete_db_file $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)

#1)
echo "creating db..." | tee -a $commands_errors_log_file
create_db_file=$main_folder'/1_create.sql'
$sql_runner $create_db_file $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)

db='sra_analysis'

#2)
echo "adding constraints..." | tee -a $commands_errors_log_file
constraints_file=$main_folder'/2_constraints.sql'
$sql_runner $constraints_file $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)

#3)
echo "adding triggers..." | tee -a $commands_errors_log_file
triggers_file=$main_folder'/3_triggers.sql'
$sql_runner $triggers_file $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)

#4)
for file_sql in $population_folder'/'*'.sql'
do
    echo "running $file_sql..." | tee -a $commands_errors_log_file
    $sql_runner $file_sql $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)
done

#5)
for file_sql in $functions_folder'/'*'.sql'
do
    echo "running $file_sql..." | tee -a $commands_errors_log_file
    $sql_runner $file_sql $user $db 1> >(tee -a $pg_log_file >&1) 2> >(tee -a $commands_errors_log_file >&2)
done

echo $(date) >>$commands_errors_log_file

echo "end" | tee -a $commands_errors_log_file
