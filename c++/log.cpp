#include <boost/log/core.hpp>
#include <boost/log/expressions.hpp>
#include <boost/log/sinks/text_file_backend.hpp>
#include <boost/log/sources/record_ostream.hpp>
#include <boost/log/sources/severity_logger.hpp>
#include <boost/log/support/date_time.hpp>
#include <boost/log/utility/setup/common_attributes.hpp>
#include <boost/log/utility/setup/console.hpp>
#include <boost/log/utility/setup/file.hpp>
#include <boost/log/trivial.hpp>

#include <string>

namespace logging   = boost::log;
namespace src       = logging::sources;
namespace sinks     = logging::sinks;
namespace keywords  = logging::keywords;
namespace expr      = logging::expressions;

void initializeLogger();
std::string setFormat();

/*
/usr/bin/g++ -g \
-I/home/fzuccato/boost/boost_1_76_0 \
/home/fzuccato/SRA/c++/log.cpp \
-o /home/fzuccato/SRA/c++/log.out \
-std=c++17 -lstdc++fs -pthread -DBOOST_LOG_DYN_LINK \
-L/home/fzuccato/boost/boost_1_76_0/stage/lib \
-lboost_log -lboost_log_setup -lboost_filesystem -lboost_thread
*/

int main() {
    
    initializeLogger();

    BOOST_LOG_TRIVIAL(trace)    << "A trace severity message";
    BOOST_LOG_TRIVIAL(debug)    << "A debug severity message";
    BOOST_LOG_TRIVIAL(info)     << "An informational severity message";
    BOOST_LOG_TRIVIAL(warning)  << "A warning severity message";
    BOOST_LOG_TRIVIAL(error)    << "An error severity message";
    BOOST_LOG_TRIVIAL(fatal)    << "A fatal severity message";

    return 0;
}

std::string setFormat() {
    return "[%TimeStamp%]\t%Severity%\t%Message%";
}

void initializeLogger() {

    logging::add_common_attributes();
    
    logging::add_console_log(
        std::cout, 
        keywords::format = setFormat()
    );
    
    logging::add_file_log (
        keywords::file_name = "sample_%N.log",
        keywords::rotation_size = 10 * 1024 * 1024,
        keywords::time_based_rotation = sinks::file::rotation_at_time_point(0, 0, 0),
        keywords::format = setFormat()
        /*keywords::format = (
            expr::stream
                << expr::format_date_time<boost::posix_time::ptime>("TimeStamp", "[%Y-%m-%d %H:%M:%S]") << "\t"
                << logging::trivial::severity << "\t" 
                << expr::smessage
        )*/
    );

    logging::core::get()->set_filter (
        logging::trivial::severity >= logging::trivial::info
    );
}