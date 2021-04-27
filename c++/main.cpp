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
//to sort vector
#include <algorithm>
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
    tuple<int, string> execAndPrint(const string& command, const SRA::Run * run, bool printOutput);
    tuple<int, string> exec(const char* command);

    //region scripts for a run
    void startRun(SRA::Run& run);
    void execFasterQDump(SRA::Run& run);
    void execKraken(SRA::Run& run);
    void execGetFastqFileSize(SRA::Run& run);
    void execDeleteFiles(SRA::Run& run);
    void endRun(SRA::Run& run);
    //region scripts for all runs
    void execUpdateAllRunsFile();

    //region useful
    void buildAndPrint(const string& line, const SRA::Run& run, bool newline);
    string buildLineToOutput(const string& line, const SRA::Run& run, bool newline);
    void removeTrailingSeparator(path& path, char separator);
    string buildCommand(const string& command, const vector<string>& parameters);
    void printAllSizesToFile(const vector<SRA::Run>& runs);
    bool compareRuns(const SRA::Run& run1, const SRA::Run& run2);

#pragma endregion methods

#pragma region variables

    #pragma region dirs

        //main directory
        path main_dir = "$HOME/SRA";
        //metadata dir path
        path metadata_dir = main_dir.native() + "/metadata";
        //scripts dir path
        path scripts_dir = main_dir.native() + "/scripts";

    #pragma endregion dirs

    #pragma region scripts

        //scripts file path
        string execFasterQDump_script   = scripts_dir.native() + "/execFasterQDump.sh";
        string execKraken_script        = scripts_dir.native() + "/execKraken.sh";
        string getFastqFileSize_script  = scripts_dir.native() + "/getFastqFileSize.sh";
        string updateAllRunsFile_script = scripts_dir.native() + "/updateAllRunsFile.sh";
        string deleteFiles_script       = scripts_dir.native() + "/deleteFiles.sh";

    #pragma endregion scripts
    
    #pragma region files

        //metadata file path
        //string allMetadataInfo_file = metadata_dir.native() + "/metadata_filtered_small.csv";
        string allMetadataInfo_file = "$HOME/SRA/c++/metadata_COPY_FOR_TESTING/metadata_COPY_FOR_TESTING.csv";

        //output files
        string resultAll_outputfile;
        string resultErr_outputfile;
        string fastQSize_outputfile;
        string updates_outputfile;

    #pragma endregion files

#pragma endregion variables

#pragma region multithread_declaration

    //max values for condition variable download
    const int maxSizeTotalDownload = 5000;
    const int maxNumOfThreadsDownload = 5;
    //actual values for condition variable download
    atomic<int> sizeTotalDownload = 0;
    atomic<int> numOfThreadsDownload = 0;

    //max values for condition variable analysis
    const int maxNumOfThreadsAnalysis = 2;
    //actual values for condition variable analysis
    atomic<int> numOfThreadsAnalysis = 0;

    //counters
    atomic<int> numOfRunsStarted = 0;
    atomic<int> numOfRunsEnded = 0;
    //total number of runs = runs.size()
    int totalNumOfRuns;

    //mutexes and condition variable
    mutex mtx_download;
    mutex mtx_analysis;
    mutex mtx_cout;
    condition_variable cv_download;
    condition_variable cv_analysis;

    //verify condition variable
    //can brings to error check values onanother method
    //bool checkConditionVariable();
    //execute a thread
    void execThread(SRA::Run& run);
    //cout with lock
    void printWithMutexLock(const string& output, bool newline);
    //print values of actual values and limits
    void printCondVarSituation();
    //print number of runs started and ended
    void printNumberOfRuns();
    //print printCondVarSituation and printNumberOfRuns
    void printDebugInfo();

#pragma endregion multithread_declaration

#pragma region main

int main(int argc, char *argv[]) {

    //cout << current_path() << "\n";
    
    const int nOfParamsNeeded = 2;
    
    //input files
    string runs_path;
    path mainOutput_dir;
    path infoFilesOutput_dir;

    #pragma region checkArgs

    //check params
    if (argc != nOfParamsNeeded + 1) {
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
    resultAll_outputfile = infoFilesOutput_dir.native() + "/results_all.csv";
    resultErr_outputfile = infoFilesOutput_dir.native() + "/results_err.csv";
    fastQSize_outputfile = infoFilesOutput_dir.native() + "/fastq_files_size.txt";
    updates_outputfile   = infoFilesOutput_dir.native() + "/updates_log.txt";

    vector<SRA::Run> runs;
    if (SRA::getRunsFromFile(runs_path, runs, ',') != 0) {
        cout << "fatal: could not open runs to execute file";
        return 4;
    }

    totalNumOfRuns = runs.size();

    sort(runs.begin(), runs.end(), compareRuns);
    
    vector<thread> threads;

    for (auto &run : runs) {
        path run_dir = mainOutput_dir.native() + "/" + run.getRunID();
        run.setFastq_dir(run_dir.native());
        threads.push_back(thread(execThread, std::ref(run)));
    }
    
    for (auto& th : threads) {

        th.join();
        
        //startRun(runs.at(i));
        //execFasterQDump(runs.at(i));
        //execGetFastqFileSize(runs.at(i));
        //execKraken(runs.at(i));
        //execDeleteFiles(runs.at(i));
        //endRun(runs.at(i));
        
        //cout << "\n";
    }

    

    //from here all runs has ended
    
    int printToFileStatus = -1;
    vector<string> resultsOfAllRuns = buildOutputForResultAllFile(runs, ',');
    printToFileStatus = SRA::printToFile(resultAll_outputfile, resultsOfAllRuns);
    if (printToFileStatus != 0) {
        cout << "error writing file " << resultAll_outputfile << "\n";
    }
    vector<string> resultsOfErrRuns = buildOutputForResultErrorFile(runs, ',');
    printToFileStatus = SRA::printToFile(resultErr_outputfile, resultsOfErrRuns);
    if (printToFileStatus != 0) {
        cout << "error writing file " << resultErr_outputfile << "\n";
    }
    vector<string> fastQSizesOfAllRuns =  buildOutputForFastQSizeFile(runs, '\t');
    printToFileStatus = SRA::printToFile(fastQSize_outputfile, fastQSizesOfAllRuns);
    if (printToFileStatus != 0) {
        cout << "error writing file " << fastQSize_outputfile << "\n";
    }
    
    execUpdateAllRunsFile();

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
tuple<int, string> execAndPrint(const string& command, const SRA::Run * run, bool printOutput) {

    //stderr redirection to stdout:
    //popen() cannot handle stderr only stdout
    string new_command = command + " 2>&1";
    //print command will be executed
    string toPrint = new_command;
    if (run != nullptr) {
        buildAndPrint(toPrint, *run, true);
    } else {
        printWithMutexLock(toPrint, true);
    }
    tuple<int, string> output = exec(new_command.c_str());
    if(printOutput) {
        vector<string> lines = SRA::split(std::get<1>(output), '\n');
        for(const auto &line: lines) {
            if (run != nullptr) {
                buildAndPrint(line, *run, true);
            } else {
                printWithMutexLock(line, true);
            }
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
    string line = "";
    while (!feof(pipe)) {
        if (fgets(buffer.data(), 128, pipe) != nullptr) {
            line = buffer.data();
            //return all output
            result += line;
            //print only current line
            //printWithMutexLock(line, true);
            //cout << line;
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
    tuple<int, string> output = execAndPrint(cmd, &run, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //download failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: FasterQDump caused error with exit code:";
        toPrint += exitCode;
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
    tuple<int, string> output = execAndPrint(cmd, &run, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //kraken failed
        run.setRunStatus(SRA::RunStatus::ERR);
        toPrint = "error: Kraken caused error with exit code: ";
        toPrint += exitCode;
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
    tuple<int, string> output = execAndPrint(cmd, &run, false);
    int exitCode = std::get<0>(output);

    if(exitCode != 0) {
        //getFastqFileSize failed: file not exist?
        run.setRunStatus(SRA::RunStatus::ERR);
        string error = std::get<1>(output);
        buildAndPrint(error, run, true);
        toPrint = "error: get FastqFileSize caused error with exit code: " + to_string(exitCode);

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
    tuple<int, string> output = execAndPrint(cmd, &run, true);
    int exitCode = std::get<0>(output);
    if (exitCode == 0) {
        toPrint = "Deleted files correctly!";
    } else {
        toPrint = "warn: error while deleting files..";
    }
    buildAndPrint(toPrint, run, true);
}

void execUpdateAllRunsFile() {
    
    //take the results of this execution and write the results, 
    //updating the metadata file with all the runs
    string toPrint = "updating all runs file...";
    printWithMutexLock(toPrint, true);
    string cmd = SRA::buildUpdateAllRunsFile_command(
        updateAllRunsFile_script, allMetadataInfo_file, resultAll_outputfile, updates_outputfile
    );
    tuple<int, string> output = execAndPrint(cmd, nullptr, true);
    int exitCode = std::get<0>(output);
    if (exitCode == 0) {
        toPrint = "Updated all runs file metadata correctly!";
    } else {
        toPrint = "error: metadata update had an error, check if original file is safe!";
    }
    printWithMutexLock(toPrint, true);
}

#pragma endregion scripts

#pragma region multithread_definition

//verify condition variable
//not a good idea to check cv_download in another method
/*
bool checkConditionVariable() { 
    //return true if only both conditions are respected
    return (
        (numOfThreadsDownload < maxNumOfThreadsDownload) &&
        (sizeTotalDownload    < maxSizeTotalDownload)            
    );
}
*/

void execThread(SRA::Run& run) {
    int size = run.getSizeCompressed();
    {
        //started critical section
        //see if thread can be executed now (otherwise wait...)
        unique_lock<mutex> lck_download(mtx_download);
        //bool ok = (numOfThreadsDownload < maxNumOfThreadsDownload) && (sizeTotalDownload + size < maxSizeTotalDownload);
        //while(!ok) cv_download.wait(lck_download);
        cv_download.wait(
            lck_download, 
            [&] { return (
                    (numOfThreadsDownload < maxNumOfThreadsDownload) && 
                    (sizeTotalDownload + size < maxSizeTotalDownload)
                );
            }
        );
    }

    this_thread::sleep_for(10000ms);


    //end critical section
    //thread has be chosen to be executed now
    
    if(! ((numOfThreadsDownload < maxNumOfThreadsDownload) && (sizeTotalDownload + size < maxSizeTotalDownload))) {
        //something gone wrong
        //wait again
        string error = "HOLY SHIT -----------------------------------------------------------------------------";
        printDebugInfo();

        buildAndPrint(error, run, true);
        {
            //started critical section
            //see if thread can be executed now (otherwise wait...)
            unique_lock<mutex> lck_download(mtx_download);
            cv_download.wait(
                lck_download, 
                [&] { return (
                        (numOfThreadsDownload < maxNumOfThreadsDownload) && 
                        (sizeTotalDownload + size < maxSizeTotalDownload)
                    );
                }
            );
        }
    }
    
    numOfThreadsDownload++;
    sizeTotalDownload += run.getSizeCompressed();
    //printDebugInfo();

    numOfRunsStarted++;
    printDebugInfo();

    startRun(run);
    execFasterQDump(run);

    numOfThreadsDownload--;
    sizeTotalDownload -= run.getSizeCompressed();

    printDebugInfo();
    //notify other threads to check , now other threads can start
    cv_download.notify_one();

    //download has ended so:
    // - meanwhile this thread ends (kraken has to be done)
    // - but don't keeping waiting the other threads
    execGetFastqFileSize(run);
    {
        //started critical section
        //see if thread can be executed now (otherwise wait...)
        unique_lock<mutex> lck_analysis(mtx_analysis);
        //bool ok = (numOfThreadsDownload < maxNumOfThreadsDownload) && (sizeTotalDownload + size < maxSizeTotalDownload);
        //while(!ok) cv_download.wait(lck);
        cv_analysis.wait(
            lck_analysis, 
            [] { return (
                    (numOfThreadsAnalysis < maxNumOfThreadsAnalysis)
                );
            }
        );
    }
    
    this_thread::sleep_for(10000ms);

    if(! (numOfThreadsAnalysis < maxNumOfThreadsAnalysis)) {
        //something gone wrong
        //wait again
        string error = "HOLY SHIT -----------------------------------------------------------------------------";
        printDebugInfo();

        buildAndPrint(error, run, true);
        {
            //started critical section
            //see if thread can be executed now (otherwise wait...)
            unique_lock<mutex> lck_analysis(mtx_analysis);
            //bool ok = (numOfThreadsDownload < maxNumOfThreadsDownload) && (sizeTotalDownload + size < maxSizeTotalDownload);
            //while(!ok) cv_download.wait(lck);
            cv_analysis.wait(
                lck_analysis, 
                [] { return (
                        (numOfThreadsAnalysis < maxNumOfThreadsAnalysis)
                    );
                }
            );
        }
    }
    numOfThreadsAnalysis++;
    printDebugInfo();
    buildAndPrint("started kraken", run, true);
    execKraken(run);

    numOfThreadsAnalysis--;
    
    printDebugInfo();

    cv_analysis.notify_one();

    execDeleteFiles(run);
    endRun(run);

    numOfRunsEnded++;
    printDebugInfo();
}

void printWithMutexLock(const string& output, bool newline) {
    {    
        unique_lock<mutex> lck(mtx_cout);
        cout << output;
        if(newline) cout << "\n";
    }
}

void printDebugInfo() {
    printNumberOfRuns();
    printCondVarSituation();
}

void printNumberOfRuns() {

    string runsStarted = "Number of threads started:\t" + to_string(numOfRunsStarted);
    runsStarted += " of " + to_string(totalNumOfRuns);
    string runsEnded = "Number of threads ended:\t" + to_string(numOfRunsEnded);
    runsEnded += " of " + to_string(totalNumOfRuns);
    printWithMutexLock(runsStarted, true);
    printWithMutexLock(runsEnded, true);

}

void printCondVarSituation() {
    string nOfThreadsDownload = "Number of threads download:\t" + to_string(numOfThreadsDownload);
    nOfThreadsDownload += " <= " + to_string(maxNumOfThreadsDownload);
    string sizeOfThreadsDownload = "Size of threads download:\t" + to_string(sizeTotalDownload);
    sizeOfThreadsDownload += " <= " + to_string(maxSizeTotalDownload);
    string nOfThreadsAnalysis = "Number of threads analysis:\t" + to_string(numOfThreadsAnalysis);
    nOfThreadsAnalysis += " <= " + to_string(maxNumOfThreadsAnalysis);
    printWithMutexLock(nOfThreadsDownload, true);
    printWithMutexLock(sizeOfThreadsDownload, true);
    printWithMutexLock(nOfThreadsAnalysis, true);
}

bool compareRuns(const SRA::Run& run1, const SRA::Run& run2) {
    //want a descending order so > instead of <
    return run1.getSizeCompressed() > run2.getSizeCompressed();
}

#pragma endregion multithread_definition