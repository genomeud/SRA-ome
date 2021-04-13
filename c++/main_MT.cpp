//for read and write on stdin/stderr
#include <iostream>
//for read and write on files
#include <fstream>
//to handle filesystem: check files and directories
#include <filesystem>
//#include <experimental/filesystem>
//for execute shell scripts
#include <cstdio>
#include <memory>
#include <stdexcept>
//for multi threading
#include <thread>
#include <atomic>
#include <condition_variable>
#include <mutex>
//other useful
#include <string>
#include <vector>
#include <sstream>
//my SRA library
#include "sra.h"

using namespace std;
//using namespace experimental::filesystem;
using namespace filesystem;

#pragma region methods

    //region exec
    tuple<int, string> exec_cout_stderr_to_stdout(const string& command, bool coutBuffer);
    tuple<int, string> exec_cout(const string& command, bool coutBuffer);
    tuple<int, string> exec_cout(const char* command, bool coutBuffer);

    //region scripts
    void startRun(SRA::Run& run);
    void execFasterQDump(SRA::Run& run);
    void execKraken(SRA::Run& run);
    void execGetFastqFileSize(SRA::Run& run);
    void execDeleteFiles(SRA::Run& run);
    void endRun(SRA::Run& run);

    //region useful
    void removeTrailingSeparator(path& path, char separator);
    string buildCommand(const string& command, const vector<string>& parameters);
    vector<string> explode(const string& line, char delim);
    void printAllSizesToFile(const vector<SRA::Run>& runs);

#pragma endregion methods

#pragma region variables

    #pragma region dirs

        //main directory
        path main_path = "$HOME/SRA";
        //metadata dir path
        path metadata_path = main_path.native() + "/metadata";
        //scripts dir path
        path scripts_path = main_path.native() + "/scripts";

    #pragma endregion dirs

    #pragma region scripts

        //scripts file path
        string execFasterQDump_script   = scripts_path.native() + "/execFasterQDump.sh";
        string execKraken_script        = scripts_path.native() + "/execKraken.sh";
        string getFastqFileSize_script  = scripts_path.native() + "/getFastqFileSize.sh";
        string updateAllRunsFile_script = scripts_path.native() + "/updateAllRunsFile.sh";
        string deleteFiles_script       = scripts_path.native() + "/deleteFiles.sh";

    #pragma endregion scripts
    
    #pragma region files

        //metadata file path
        string allMetadataInfo_file = metadata_path.native() + "/metadata_filtered_small.csv";

        //output files
        string resultAll_path;
        string resultErr_path;
        string fastQSize_path;
        string updates_path;

    #pragma endregion files

#pragma endregion variables

#pragma region constants

    //indexes of columns in file 'runs_list.csv'
    const int RUN_IDX = 0;
    const int LAYOUT_IDX = 1;
    const int COMPRESSED_SIZE_IDX = 2;

#pragma endregion constants

#pragma region multithread_declaration

    //max values for condition variable
    const int maxSizeTotalDownload = 5000;
    const int maxNumOfThreadsDownload = 5;
    //actual values for condition variable
    atomic<int> sizeTotalDownload = 0;
    atomic<int> numOfThreadsDownload = 0;

    //mutexes and condition variable
    mutex mtx_exec;
    mutex mtx_cout;
    condition_variable cv;

    //verify condition variable
    //can brings to error check values onanother method
    //bool checkConditionVariable();
    //execute a thread
    void execThread(SRA::Run& run);
    //cout with lock
    void printWithMutexLock(const string& output, bool newline);
    //print values of actual values and limits
    void printCondVarSituation();

#pragma endregion multithread_declaration

#pragma region main

int main(int argc, char *argv[]) {
    
    const int nOfParamsNeeded = 2;
    
    //input files
    const char *runs_path;
    path mainOutput_dir;
    path infoFilesOutput_dir;

    #pragma region checkArgs

    //check params
    if (argc < nOfParamsNeeded) {
        cout << "usage: " << argv[0] << " <runsToExecute> <outputDir>\n";
        return 1;
    } else {
        runs_path = argv[1];
        mainOutput_dir = argv[2];
        removeTrailingSeparator(mainOutput_dir, '/');
        infoFilesOutput_dir = mainOutput_dir.native() + "/.info";
    }
    
    //check if main output directory exists
    if(!exists(mainOutput_dir)) {
        if(create_directory(mainOutput_dir)) {
            cout << "warn: main output directory didn't exists, created\n";
        } else {
            cout << "fatal: main output directory didn't exists, creation failed\n";
            return 2;
        }
    }
    
    //check if info files output directory exists
    if(!exists(infoFilesOutput_dir)) {
        if(create_directory(infoFilesOutput_dir)) {
            cout << "warn: info files output directory didn't exists, created\n";
        } else {
            cout << "fatal: info files output directory didn't exists, creation failed\n";
            return 3;
        }
    }
    
    #pragma endregion checkArgs
    
    //output files
    resultAll_path = infoFilesOutput_dir.native() + "/results_all.csv";
    resultErr_path = infoFilesOutput_dir.native() + "/results_err.csv";
    fastQSize_path = infoFilesOutput_dir.native() + "/fastq_files_size.csv";
    updates_path   = infoFilesOutput_dir.native() + "/updates_log.csv";

    //open runs list file in read mode
    ifstream runs_ifs(runs_path);

    //check if it is open
    if (!runs_ifs.is_open()) {
        cout << "fatal: could not open runs to execute file";
        return 4;
    }

    char delimiter = ',';
    string raw_line;
    vector<SRA::Run> runs;

    //read csv file store each line data to an instance of class Run
    while (getline(runs_ifs, raw_line)) {
        vector<string> line = explode(raw_line, delimiter);
        string runID = line[RUN_IDX];
        SRA::Layout runLayout = SRA::layoutMap.at(line[LAYOUT_IDX]);
        int runSizeCompressed = stoi(line[COMPRESSED_SIZE_IDX]);
        //cout << ID << "\t" << SRA::to_string(runLayout) << "\t" << runSizeCompressed << "\n";
        path run_dir = mainOutput_dir.native() + "/" + runID;
        SRA::Run run(runID, run_dir.native(), runLayout, runSizeCompressed);
        runs.push_back(run);
    }

    vector<thread> threads;

    for (auto &run : runs) {
        threads.push_back(thread(execThread, std::ref(run)));
    }
    
    //for (auto& th : threads) {
    for(int i = 0; i < threads.size(); i++) {

        //th.join();
        threads[i].join();
        
        //startRun(runs.at(i));
        //execFasterQDump(runs.at(i));
        execGetFastqFileSize(runs.at(i));
        execKraken(runs.at(i));
        execDeleteFiles(runs.at(i));
        endRun(runs.at(i));
        
        //cout << "\n";
    }

    return 0;
}

#pragma endregion main

#pragma region exec

/*
if coutBuffer == TRUE: 
    output will be printed to cout
    return type: <exitStatus, nullptr>
useful if is important if everything done correctly
output generated just print it out, don't return it

if coutBuffer == FALSE: 
    output will be returned
    return type: <exitStatus, buffer>
useful if is important the output generated
*/

tuple<int, string> exec_cout_stderr_to_stdout(const string& command, bool coutBuffer) {

    string new_command = command + " 2>&1";
    printWithMutexLock(new_command, true);
    tuple<int, string> output = exec_cout(new_command, coutBuffer);
    //int exitStatus = std::get<0>(output);
    //cout << "exitStatus: " << exitStatus << "\n";
    return output;
}

tuple<int, string>  exec_cout(const string& command, bool coutBuffer) {
    return exec_cout(command.c_str(), coutBuffer);
}

tuple<int, string> exec_cout(const char* command, bool coutBuffer) {
    array<char, 128> buffer;
    string result;
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        throw runtime_error("popen() failed!");
    }
    while (!feof(pipe)) {
        if (fgets(buffer.data(), 128, pipe) != nullptr) {
            result = buffer.data();
        }
    }
    if(coutBuffer) {
        printWithMutexLock(result, false);
    }
    int exitStatus = WEXITSTATUS(pclose(pipe));
    string output = coutBuffer ? "" : result;
    return std::make_tuple(exitStatus, output);    
}

#pragma endregion exec

#pragma region useful

void removeTrailingSeparator(path& path, char separator) {
    string p = path.c_str();
    int n = p.size();
    if(p[n-1] == separator) {
        path = path.parent_path();
    }
    //cout << path << "\n";
}

vector<string> explode(const string& line, char delim) {
    vector<string> result;
    istringstream iss(line);
    for (string token; getline(iss, token, delim);) {
        result.push_back(move(token));
    }
    return result;
}

string buildCommand(const string& command, const vector<string>& parameters) {
    string cmd = command + " ";
    for(auto const &param : parameters) {
        cmd += param;
        cmd += " ";
    }
    return cmd;
}

void printAllSizesToFile(const vector<SRA::Run>& runs) {
    for(auto const &run : runs) {
        //if size >= 0 ==> std::to_string(size)
        //if size  < 0 ==> error ==> some string error
        string sizeUncompressed = SRA::sizeToString(run.getSizeUncompressed());

        //print to file size compressed and uncompressed
        //TODO
    }
}

#pragma endregion useful

#pragma region scripts

void startRun(SRA::Run& run) {
    run.setRunStatus(SRA::RunStatus::OK);
    string toPrint = "started: " + run.to_string();
    printWithMutexLock(toPrint, true);
    //printWithMutexLock(run.to_json(), true);
    run.setInProcess(true);
}

void endRun(SRA::Run& run) {
    string toPrint = "ended: " + run.to_string();
    printWithMutexLock(toPrint, true);
    //printWithMutexLock(run.to_json(), true);
    run.setInProcess(false);
}

void execFasterQDump(SRA::Run& run) {
    string toPrint = "downloading run as .fastq...";
    printWithMutexLock(toPrint, true);
    string cmd = SRA::buildFasterQDump_command(
        execFasterQDump_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //download failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: FasterQDump caused error with exit code:" + exitCode;
        printWithMutexLock(toPrint, true);   
    } else {
        toPrint = "download done correctly!";
        printWithMutexLock(toPrint, true);
    }

}

void execKraken(SRA::Run& run) {
    string toPrint = "analysing run with Kraken2...";
    printWithMutexLock(toPrint, true);
    string cmd = SRA::buildKraken_command(
        execKraken_script, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //kraken failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: Kraken caused error with exit code:" + exitCode;
        printWithMutexLock(toPrint, true);    
    } else {
        toPrint = "Kakren: analysed correctly!";
        printWithMutexLock(toPrint, true);
    }
}

void execGetFastqFileSize(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    string toPrint = "looking for fastq file size...";
    printWithMutexLock(toPrint, true);
    string cmd = SRA::buildGetFastqFileSize_command(
        getFastqFileSize_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, false);
    int exitCode = std::get<0>(output);

    if(exitCode != 0) {
        //getFastqFileSize failed: file not exist?
        run.setRunStatus(SRA::RunStatus::ERR);
        string error = std::get<1>(output);
        printWithMutexLock(error, false);
        toPrint = "error: get FastqFileSize caused error with exit code:" + exitCode;
        printWithMutexLock(toPrint, true);

    } else {
        //getFastqFileSize ok
        int sizeUncompressed = stoi(std::get<1>(output));
        run.setSizeUncompressed(sizeUncompressed);
        toPrint = "Fastq file size obtained correctly!";
        printWithMutexLock(toPrint, true);
    }
}

void execDeleteFiles(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    string toPrint = "deleting fastq files...";
    printWithMutexLock(toPrint, true);
    string cmd = SRA::buildDeleteFiles_command(
        deleteFiles_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if (exitCode == 0) {
        toPrint = "Deleted files correctly!";
        printWithMutexLock(toPrint, true);
    } else {
        toPrint = "warn: error while deleting files..";
        printWithMutexLock(toPrint, true);
    }
}

#pragma endregion scripts


#pragma region multithread_definition

//verify condition variable
//not a good idea to check cv in another method
/*
bool checkConditionVariable() { 
    //return true if only both conditions are respected
    return (
        (numOfThreadsDownload < maxNumOfThreadsDownload) &&
        (sizeTotalDownload    < maxSizeTotalDownload)            
    );
}
*/

//execute a thread
void execThread(SRA::Run& run) {
    {
        unique_lock<mutex> lck(mtx_exec);
        //while(!ok) cv.wait(lck);
        cv.wait(
            lck, 
            []{ return (
                    (numOfThreadsDownload < maxNumOfThreadsDownload) && 
                    (sizeTotalDownload < maxSizeTotalDownload)
                );
            }
        );
    }
    //started critical section
    numOfThreadsDownload++;
    sizeTotalDownload += run.getSizeCompressed();
    //printCondVarSituation();

    startRun(run);
    execFasterQDump(run);

    //end critical section
    numOfThreadsDownload--;
    sizeTotalDownload -= run.getSizeCompressed();

    //printCondVarSituation();
    //notify other threads to check cv: this thread has finished
    cv.notify_all();
}

void printWithMutexLock(const string& output, bool newline) {
    {
        unique_lock<mutex> lck(mtx_cout);
        cout << output;
        if(newline) cout << "\n";
    }
}

void printCondVarSituation() {
    string nOfThreads = "NumOfThreads: " + to_string(numOfThreadsDownload);
    nOfThreads += " <= " + to_string(maxNumOfThreadsDownload);
    string memory = "TotMemoryUsed: " + to_string(sizeTotalDownload);
    memory += " <= " + to_string(maxSizeTotalDownload);
    printWithMutexLock(nOfThreads, true);
    printWithMutexLock(memory, true);
}

#pragma endregion multithread_definition