#ifndef RUN_STATUS_HPP
#define RUN_STATUS_HPP

#include <map>
#include <string>
#include <iostream>

namespace SRA {

	enum class RunStatus {
		TO_DO,
		OK,
		ERR,
		IGNORE
	};

	extern std::map<std::string, RunStatus> runStatusMap;
	/*extern std::map<std::string, RunStatus> runStatusMap = {
		{ "TO_DO",  RunStatus::TO_DO  },
		{ "OK",     RunStatus::OK     },
		{ "ERR",    RunStatus::ERR    },
		{ "IGNORE", RunStatus::IGNORE }
	};*/
	
	std::string inline to_string(const RunStatus& status) {
		switch(status) {
			case RunStatus::TO_DO:	return "TO_DO";	 break;
			case RunStatus::OK:  	return "OK";	 break;
			case RunStatus::ERR: 	return "ERR";	 break;
			case RunStatus::IGNORE:	return "IGNORE"; break;
		}
		return nullptr;
	}
	
	/*
	inline std::ostream &operator << (std::ostream &os, const RunStatus &status) {
		switch(status)
		{
			case RunStatus::TO_DO:  os << "TO_DO";  break;
			case RunStatus::OK:     os << "OK";     break;
			case RunStatus::ERR:    os << "ERR";    break;
			case RunStatus::IGNORE: os << "IGNORE"; break;
		}
		return os;
	}
	*/
}

#endif // !RUN_STATUS_H
