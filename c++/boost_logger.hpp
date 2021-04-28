#ifndef BOOST_LOGGER_HPP
#define BOOST_LOGGER_HPP

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
namespace src       = boost::log::sources;
namespace sinks     = boost::log::sinks;
namespace keywords  = boost::log::keywords;
namespace expr      = boost::log::expressions;

#define TRACE   boost::log::trivial::trace 
#define DEBUG   boost::log::trivial::debug 
#define INFO    boost::log::trivial::info 
#define WARNING boost::log::trivial::warning 
#define ERROR   boost::log::trivial::error 
#define FATAL   boost::log::trivial::fatal 

namespace BoostLogger {

    void initializeLogger(
        const logging::trivial::severity_level& minLevel, 
        bool enableFile, 
        bool enableConsole, 
        const std::string& logFile,
        const std::string& format
    );

    std::string getDefaultFormat();

}


#endif