#ifndef RUN_HPP
#define RUN_HPP

#include <filesystem>
#include <string>
#include "layout.hpp"
#include "runstatus.hpp"

namespace SRA {

    class Run {

        private:

            //attributes
            std::string ID;
            Layout layout;
            int sizeCompressed = -1;
            int sizeNotCompressed = -1;
            bool inProcess = false;
            RunStatus status = RunStatus::TO_DO;
            std::string fastq_dir;

        public:

            //constructor
            Run(std::string ID, Layout layout, int sizeCompressed);

            //getters
            std::string getRunID() const;
            Layout getLayout() const;
            int getSizeCompressed() const;
            int getSizeUncompressed() const;
            RunStatus getRunStatus() const;
            bool getInProcess() const;
            std::string getFastq_dir();

            //setters
            void setSizeUncompressed(int sizeNotCompressed);
            void setRunStatus(RunStatus status);
            void setInProcess(bool inProcess);
            void setFastq_dir(std::string fastq_dir);

            //methods
            std::string to_string(char separator) const;
            std::string to_json() const;
            std::string getIdLayoutSizeCompressed(char separator) const;
    };

}

#endif