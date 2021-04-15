
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
const int RUN_IDX = 0;
const int LAYOUT_IDX = 1;
const int COMPRESSED_SIZE_IDX = 2;

using namespace std;


namespace SRA {

    //methods declaration
    string buildFasterQDump_command(const string& command, const Run& run, const string& output_dir);
    string buildKraken_command(const string& command, const string& input_dir);
    string buildGetFastqFileSize_command(const string& command, const Run& run, const string& input_dir);
    string buildDeleteFiles_command(const string& command, const Run& run, const string& dir);
    string sizeToString(int size);
    int getRunsFromFile(const string& filePath, OUT vector<Run>& runs, char delimiter);
    vector<string> explode(const string& line, char delim);


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

    string sizeToString(int size) {
        //size < 0 ==> got some error
        return size >= 0 ? std::to_string(size) : "NO_FASTQ_FOUND";
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
            vector<string> line = explode(raw_line, delimiter);
            string runID = line[RUN_IDX];
            Layout runLayout = layoutMap.at(line[LAYOUT_IDX]);
            int runSizeCompressed = stoi(line[COMPRESSED_SIZE_IDX]);
            Run run(runID, runLayout, runSizeCompressed);    
            runs.push_back(run);
        }
        return 0;

    }
    
    vector<string> explode(const string& line, char delim) {
        vector<string> result;
        istringstream iss(line);
        for (string token; getline(iss, token, delim);) {
            result.push_back(move(token));
        }
        return result;
    }

}

#endif