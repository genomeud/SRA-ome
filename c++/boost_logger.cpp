#include "boost_logger.hpp"

#include <string>

namespace BoostLogger {
        
    std::string getDefaultFormat() {
        return "%TimeStamp%\t%ThreadID%\t%Severity%\t%Message%";
    }

    void initializeLogger(const logging::trivial::severity_level& minLevel, bool enableFile, bool enableConsole, const std::string& logFile, const std::string& format) {
        
        if(enableConsole) {
            logging::add_console_log(
                std::cout, 
                keywords::format = format
            );
        }

        if(enableFile) {
            logging::add_file_log (
                keywords::file_name = logFile,
                keywords::rotation_size = 10 * 1024 * 1024,
                //keywords::time_based_rotation = sinks::file::rotation_at_time_point(0, 0, 0),
                keywords::format = format
                /*keywords::format = (
                    expr::stream
                        << expr::format_date_time<boost::posix_time::ptime>("TimeStamp", "[%Y-%m-%d %H:%M:%S]") << "\t"
                        << logging::trivial::severity << "\t" 
                        << expr::smessage
                )*/
            );
        }      
        
        logging::add_common_attributes();

        logging::core::get()->set_filter (
            logging::trivial::severity >= minLevel
        );
    }

}
