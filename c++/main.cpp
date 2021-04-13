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
//other useful
#include <string>
#include <vector>
#include <sstream>
//mine
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
    void execFasterQDump(SRA::Run& run);
    void execKraken(SRA::Run& run);
    void execGetFastqFileSize(SRA::Run& run);
    void execDeleteFiles(SRA::Run& run);

    //region useful
    string buildCommand(string command, vector<string> parameters);
    vector<string> explode(string const& line, char delim);
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
        SRA::Run run(runID, run_dir, runLayout, runSizeCompressed);
        runs.push_back(run);
    }

    for (auto &run : runs) {

        run.setRunStatus(SRA::RunStatus::OK);
        
        //cout << run.to_string() << "\n";
        cout << run.to_json() << "\n";
        run.setInProcess(true);

        execFasterQDump(run);
        execGetFastqFileSize(run);
        execKraken(run);
        execDeleteFiles(run);
        run.setInProcess(false);
        
        cout << "\n";
    }

    return 0;
}

#pragma end region main

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
    cout << new_command << "\n";
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
            if(coutBuffer) {
                cout << result;
            }
        }
    }
    int exitStatus = WEXITSTATUS(pclose(pipe));
    string output = coutBuffer ? "" : result;
    return std::make_tuple(exitStatus, output);    
}

#pragma endregion exec

#pragma region useful
vector<string> explode(string const& line, char delim) {
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

void execFasterQDump(SRA::Run& run) {
    cout << "downloading run as .fastq...\n";
    string cmd = SRA::buildFasterQDump_command(
        execFasterQDump_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //download failed
        run.setRunStatus(SRA::RunStatus::ERR);
        cout << "error: FasterQDump caused error with exit code:" << exitCode << "\n";   
    } else {
        cout << "download done correctly!\n";
    }

}

void execKraken(SRA::Run& run) {
    cout << "analysing run with Kraken2...\n";
    string cmd = SRA::buildKraken_command(
        execKraken_script, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if(exitCode != 0) {
        //kraken failed
        run.setRunStatus(SRA::RunStatus::ERR);
        cout << "error: Kraken caused error with exit code:" << exitCode << "\n";    
    } else {
        cout << "Kakren: analysed correctly!\n";
    }
}

void execGetFastqFileSize(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    cout << "looking for fastq file size...\n";
    string cmd = SRA::buildGetFastqFileSize_command(
        getFastqFileSize_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, false);
    int exitCode = std::get<0>(output);

    if(exitCode != 0) {
        //getFastqFileSize failed: file not exist?
        run.setRunStatus(SRA::RunStatus::ERR);
        string error = std::get<1>(output);
        cout << error << "\n";
        cout << "error: get FastqFileSize caused error with exit code:" << exitCode << "\n";

    } else {
        //getFastqFileSize ok
        int sizeUncompressed = stoi(std::get<1>(output));
        run.setSizeUncompressed(sizeUncompressed);
        cout << "Fastq file size obtained correctly!\n";
    }
}

void execDeleteFiles(SRA::Run& run) {
    //calculate from filesystem fastq file uncompressed size
    cout << "deleting fastq files...\n";
    string cmd = SRA::buildDeleteFiles_command(
        deleteFiles_script, run, run.getFastq_dir()
    );
    tuple<int, string> output = exec_cout_stderr_to_stdout(cmd, true);
    int exitCode = std::get<0>(output);
    if (exitCode == 0) {
        cout << "Deleted files correctly!\n";
    } else {
        cout << "warn: error while deleting files..\n";
    }
}

#pragma endregion scripts
