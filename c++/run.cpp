#include "run.h"
#include <string>
#include <filesystem>

namespace SRA {

    Run::Run(std::string ID, Layout layout, int sizeCompressed) {
        this->ID = ID;
        this->layout = layout;
        this->sizeCompressed = sizeCompressed;
    }

    //getters

    std::string Run::getRunID() const {
        return ID;
    }

    Layout Run::getLayout() const {
        return layout;
    }

    int Run::getSizeCompressed() const {
        return sizeCompressed;
    }

    int Run::getSizeUncompressed() const {
        return sizeNotCompressed;
    }

    RunStatus Run::getRunStatus() const {
        return status;
    }

    bool Run::getInProcess() const {
        return this->inProcess;
    }
    
    std::string Run::getFastq_dir() {
        return this->fastq_dir;
    }

    //setters

    void Run::setSizeUncompressed(int sizeNotCompressed) {
        this->sizeNotCompressed = sizeNotCompressed;
    }

    void Run::setRunStatus(RunStatus status) {
        this->status = status;
    }

    void Run::setInProcess(bool inProcess) {
        this->inProcess = inProcess;
    }

    void Run::setFastq_dir(std::string fastq_dir) {
        this->fastq_dir = fastq_dir;
    }

    // methods
    std::string Run::to_json() const {

        std::string run = "";

        run += "{\n";
        run += "\trun: " + ID + ",\n";
        run += "\tlayout: " + SRA::to_string(layout) + ",\n";
        run += "\tsize_compressed: " + std::to_string(sizeCompressed) + ",\n";
        run += "\tsize_not_compressed: " + std::to_string(sizeNotCompressed)  + ",\n";
        run += "\tin_process: " + std::to_string(inProcess) + ",\n";
        run += "\tstatus: " + SRA::to_string(status) + ",\n";
        run += "},";

        return run;
    }


    std::string Run::to_string() const {

        std::string run = "";
        
        run += ID + "\t";
        run += SRA::to_string(layout) + "\t";
        run += std::to_string(sizeCompressed) + "\t";
        run += std::to_string(sizeNotCompressed) + "\t";
        run += std::to_string(inProcess) + "\t";
        run += SRA::to_string(status);

        return run;
    }
}
