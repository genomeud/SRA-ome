//to read and write on stdin/stderr
#include <iostream>
//to read and write on files
#include <fstream>
//to handle filesystem: check files and directories
#include <filesystem>
//#include <experimental/filesystem>
//to execute shell scripts
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
//to get actual time for log
#include <time.h>
//my SRA library
#include "sra.h"

using namespace std;
//using namespace experimental::filesystem;
using namespace filesystem;

#pragma region methods

    //region exec
    tuple<int, string> execAndPrint(const string& command, const SRA::Run& run, bool printOutput);
    tuple<int, string> exec(const char* command);

    //region scripts
    void startRun(SRA::Run& run);
    void execFasterQDump(SRA::Run& run);
    void execKraken(SRA::Run& run);
    void execGetFastqFileSize(SRA::Run& run);
    void execDeleteFiles(SRA::Run& run);
    void endRun(SRA::Run& run);

    //region useful
    void buildAndPrint(const string& line, const SRA::Run& run, bool newline);
    string buildLineToOutput(const string& line, const SRA::Run& run, bool newline);
    void removeTrailingSeparator(path& path, char separator);
    string buildCommand(const string& command, const vector<string>& parameters);
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
    string runs_path;
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

    vector<SRA::Run> runs;
    if (SRA::getRunsFromFile(runs_path, runs, ',') != 0) {
        cout << "fatal: could not open runs to execute file";
        return 4;
    }

    vector<thread> threads;

    for (auto &run : runs) {
        path run_dir = mainOutput_dir.native() + "/" + run.getRunID();
        run.setFastq_dir(run_dir.native());
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

    cout << "ended everything ok!\n";
    
    return 0;
}

#pragma endregion main

#pragma region exec

/*
if printOutput == TRUE: 
    output will be printed to cout
    return type: <exitStatus, nullptr>
useful if is important if everything done correctly
output generated just print it out, don't return it

if printOutput == FALSE: 
    output will be returned
    return type: <exitStatus, buffer>
useful if is important the output generated
*/
tuple<int, string> execAndPrint(const string& command, const SRA::Run& run, bool printOutput) {

    //stderr redirection to stdout:
    //popen() cannot handle stderr only stdout
    string new_command = command + " 2>&1";
    //print command will be executed
    string toPrint = new_command;
    buildAndPrint(toPrint, run, true);
    tuple<int, string> output = exec(new_command.c_str());
    if(printOutput) {
        vector<string> lines = SRA::explode(std::get<1>(output), '\n');
        for(const auto &line: lines) {
            buildAndPrint(line, run, true);
        }
    }
    return output;
}

tuple<int, string> exec(const char* command) {
    array<char, 128> buffer;
    string result = "";
    FILE *pipe = popen(command, "r");
    if (!pipe) {
        throw runtime_error("popen() failed!");
    }
    while (!feof(pipe)) {
        if (fgets(buffer.data(), 128, pipe) != nullptr) {
            result += buffer.data();
        }
    }
    int exitStatus = WEXITSTATUS(pclose(pipe));
    return std::make_tuple(exitStatus, result);  
}

#pragma endregion exec

#pragma region useful

void buildAndPrint(const string& line, const SRA::Run& run, bool newline) {
    string toPrint = buildLineToOutput(line, run, false);
    printWithMutexLock(toPrint, newline);
}

string buildLineToOutput(const string& line, const SRA::Run& run, bool newline) {
    // Current date/time based on current system
    time_t now = time(0);
    // Convert now to tm struct for local timezone
    struct tm* localtm = localtime(&now);
    char separator = '\t';
    const int bufSize = 80;
    char timeBuffer [bufSize];
    strftime(timeBuffer, bufSize, "%F %T", localtm);
    std::string toPrint = timeBuffer;
    toPrint += separator;
    toPrint += run.getRunID();
    toPrint += separator;
    toPrint += line;
    if(newline) toPrint += '\n';
    return toPrint;
}

void removeTrailingSeparator(path& path, char separator) {
    string p = path.c_str();
    int n = p.size();
    if(p[n-1] == separator) {
        path = path.parent_path();
    }
    //cout << path << "\n";
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
    buildAndPrint(toPrint, run, true);
    run.setInProcess(true);
}

void endRun(SRA::Run& run) {
    string toPrint = "ended: " + run.to_string();
    buildAndPrint(toPrint, run, true);
    run.setInProcess(false);
}

void execFasterQDump(SRA::Run& run) {
    string toPrint = "downloading run as .fastq...";
    buildAndPrint(toPrint, run, true);
    string cmd = SRA::buildFasterQDump_command(
        execFasterQDump_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = execAndPrint(cmd, run, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //download failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: FasterQDump caused error with exit code:" + exitCode;
    } else {
        toPrint = "download done correctly!";
    }
    buildAndPrint(toPrint, run, true);

}

void execKraken(SRA::Run& run) {
    string toPrint = "analysing run with Kraken2...";
    buildAndPrint(toPrint, run, true);
    string cmd = SRA::buildKraken_command(
        execKraken_script, run.getFastq_dir()
    );
    tuple<int, string> output = execAndPrint(cmd, run, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //kraken failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: Kraken caused error with exit code:" + exitCode;
    } else {
        toPrint = "Kakren: analysed correctly!";
    }
    buildAndPrint(toPrint, run, true);
}

void execGetFastqFileSize(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    string toPrint = "looking for fastq file size...";
    buildAndPrint(toPrint, run, true);
    string cmd = SRA::buildGetFastqFileSize_command(
        getFastqFileSize_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = execAndPrint(cmd, run, false);
    int exitCode = std::get<0>(output);

    if(exitCode != 0) {
        //getFastqFileSize failed: file not exist?
        run.setRunStatus(SRA::RunStatus::ERR);
        string error = std::get<1>(output);
        buildAndPrint(toPrint, run, false);
        toPrint = "error: get FastqFileSize caused error with exit code:" + exitCode;

    } else {
        //getFastqFileSize ok
        int sizeUncompressed = stoi(std::get<1>(output));
        run.setSizeUncompressed(sizeUncompressed);
        toPrint = "Fastq file size obtained correctly!";
    }
    buildAndPrint(toPrint, run, true);
}

void execDeleteFiles(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    string toPrint = "deleting fastq files...";
    buildAndPrint(toPrint, run, true);
    string cmd = SRA::buildDeleteFiles_command(
        deleteFiles_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = execAndPrint(cmd, run, true);
    int exitCode = std::get<0>(output);
    if (exitCode == 0) {
        toPrint = "Deleted files correctly!";
    } else {
        toPrint = "warn: error while deleting files..";
    }
    buildAndPrint(toPrint, run, true);
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
            [] { return (
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