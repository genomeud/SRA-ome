#ifndef SEVERITY_LEVEL_HPP
#define SEVERITY_LEVEL_HPP

#include <string>
#include <iostream>


enum class SeverityLevel {
	TRACE = 0,
	DEBUG = 1,
	INFO = 2,
	WARNING = 3,
	ERROR = 4,
	FATAL = 5
};

std::string inline to_string(const SeverityLevel& severityLevel) {
	switch(severityLevel) {
		case SeverityLevel::TRACE:	 return "trace";	break;
		case SeverityLevel::DEBUG:   return "debug";	break;
		case SeverityLevel::INFO:    return "info";	    break;
		case SeverityLevel::WARNING: return "warning";	break;
		case SeverityLevel::ERROR:   return "error";	break;
		case SeverityLevel::FATAL:   return "fatal";	break;
	}
	return nullptr;
}



#endif