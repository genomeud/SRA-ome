
#ifndef SRA_H
#define SRA_H

#include <map>
#include <string>
#include <iostream>

#include "run.h"

using namespace std;


namespace SRA {

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

}

#endif