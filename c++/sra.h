
#ifndef SRA_H
#define SRA_H

#include <map>
#include <string>
#include <iostream>
#include <fstream>
#include <utility>

#include "run.h"

#define OUT

//indexes of columns in file 'runs_list.csv'
const int RUNIDX_IN_RUNSLIST = 0;
const int LAYOUTIDX_IN_RUNSLIST = 1;
const int COMPRSIZEIDX_IN_RUNSLIST = 2;

//indexes of columns in file 'metadata_filtered_small.csv'
const int RUNIDX_IN_METADATA = 8;
const int STATUSIDX_IN_METADATA = 19;

//indexes of columns in file 'updates_log.txt'
//file exists and is printed after executing printToFile( buildOutputForResultAllFile() )
const int RUNIDX_IN_RESULTALL = 1;
const int STATUSIDX_IN_RESULTALL = 2;

using namespace std;


namespace SRA {

    //methods declaration
    //command building
    string buildFasterQDump_command(const string& command, const Run& run, const string& output_dir);
    string buildKraken_command(const string& command, const string& input_dir);
    string buildGetFastqFileSize_command(const string& command, const Run& run, const string& input_dir);
    string buildDeleteFiles_command(const string& command, const Run& run, const string& dir);
    string buildUpdateAllRunsFile_command(const string& command, const string& metadata_inputfile, const string& resultAll_inputfile, const string& updatesLog_outputfile);
    //output building
    vector<string> buildOutputForResultAllFile(const vector<Run>& runs, char delimiter);
    vector<string> buildOutputForResultErrorFile(const vector<Run>& runs, char delimiter);
    vector<string> buildOutputForFastQSizeFile(const vector<Run>& runs, char delimiter);
    //output printing
    int printToFile(const string& file_path, const vector<string>& lines);
    //useful methods
    string getIfNonNegativeSizeAsStringElseErrorString(int size);
    int getRunsFromFile(const string& filePath, OUT vector<Run>& runs, char delimiter);
    vector<string> split(const string& line, char delim);


    //string to enum

    map<string, Layout> layoutMap = {
        { "SINGLE", Layout::SINGLE },
        { "PAIRED", Layout::PAIRED }
    };

    map<string, RunStatus> runStatusMap = {
        { "TO_DO",  RunStatus::TO_DO },
        { "OK",     RunStatus::OK    },
        { "ERR",    RunStatus::ERR   }
    };

    string buildFasterQDump_command(const string& command, const Run& run, const string& output_dir) {
        
        string cmd = command + " ";
        cmd += run.getRunID() + " ";
        cmd += to_string(run.getLayout()) + " ";
        cmd += output_dir;
        return cmd;
    }

    string buildKraken_command(const string& command, const string& input_dir) {
        string cmd = command + " ";
        cmd += input_dir;
        return cmd;
    }

    string buildGetFastqFileSize_command(const string& command, const Run& run, const string& input_dir) {
        string cmd = command + " ";
        cmd += input_dir + " ";
        cmd += run.getRunID() + " ";
        cmd += to_string(run.getLayout());
        return cmd;
    }

    string buildDeleteFiles_command(const string& command, const Run& run, const string& dir) {
        string cmd = command + " ";
        cmd += run.getRunID() + " ";
        cmd += dir;
        return cmd;
    }

    string buildUpdateAllRunsFile_command(const string& command, const string& metadata_inputfile, const string& resultAll_inputfile, const string& updatesLog_outputfile) {
        string cmd = command + " ";
        cmd += metadata_inputfile + " ";
        cmd += std::to_string(RUNIDX_IN_METADATA) + " ";
        cmd += std::to_string(STATUSIDX_IN_METADATA) + " ";
        cmd += resultAll_inputfile + " ";
        cmd += std::to_string(RUNIDX_IN_RESULTALL) + " ";
        cmd += std::to_string(STATUSIDX_IN_RESULTALL) + " ";
        cmd += updatesLog_outputfile;
        return cmd;
    }

    string getIfNonNegativeSizeAsStringElseErrorString(int size) {
        //size < 0 ==> got some error
        return size >= 0 ? std::to_string(size) : "NO_FASTQ_FOUND";
    }
    
    vector<string> split(const string& line, char delim) {
        vector<string> result;
        istringstream iss(line);
        for (string token; getline(iss, token, delim);) {
            result.push_back(move(token));
        }
        return result;
    }

    int getRunsFromFile(const string& filePath, OUT vector<Run>& runs, char delimiter) {
        const char * path = filePath.c_str();
        //open runs list file in read mode
        ifstream runs_ifs(path);
        //check if it is open
        if (!runs_ifs.is_open()) return 1;
        string raw_line;
        //read csv file store each line data to an instance of class Run
        while (getline(runs_ifs, raw_line)) {
            vector<string> line = split(raw_line, delimiter);
            string runID = line[RUNIDX_IN_RUNSLIST];
            Layout runLayout = layoutMap.at(line[LAYOUTIDX_IN_RUNSLIST]);
            int runSizeCompressed = stoi(line[COMPRSIZEIDX_IN_RUNSLIST]);
            Run run(runID, runLayout, runSizeCompressed);    
            runs.push_back(run);
        }
        return 0;
    }

    int printToFile(const string& file_path, const vector<string>& lines) {
        ofstream file_ofs(file_path);
        if (!file_ofs.is_open()) return 1;
        for (auto const &line : lines) {
            file_ofs << line;
        }
        return 0;
    }

    vector<string> buildOutputForResultAllFile(const vector<Run>& runs, char delimiter) {
        vector<string> lines;
        for (auto const &run : runs) {
            string line = run.getRunID();
            line += delimiter;
            line += to_string(run.getRunStatus());
            line += "\n";
            lines.push_back(line);
        }
        return lines;
    }
    
    vector<string> buildOutputForResultErrorFile(const vector<Run>& runs, char delimiter) {
        vector<string> lines;
        for (auto const &run : runs) {
            if(run.getRunStatus() == RunStatus::ERR) {
                string line = run.getRunID();
                line += delimiter;
                line += to_string(run.getRunStatus());
                line += "\n";
                lines.push_back(line);
            }
        }
        return lines;
    }
    
    vector<string> buildOutputForFastQSizeFile(const vector<Run>& runs, char delimiter) {
        vector<string> lines;
        for (auto const &run : runs) {
            string line = run.getRunID();
            line += delimiter;
            line += std::to_string(run.getSizeCompressed());
            line += delimiter;
            line += getIfNonNegativeSizeAsStringElseErrorString(run.getSizeUncompressed());
            line += "\n";
            lines.push_back(line);
        }
        return lines;
    }

}

#endif