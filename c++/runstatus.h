#ifndef RUN_STATUS_H
#define RUN_STATUS_H

#include <map>
#include <string>
#include <iostream>

namespace SRA {

	enum class RunStatus {
		NO,
		OK,
		ERR
	};

	extern std::map<std::string, RunStatus> runStatusMap;
	/*extern std::map<std::string, RunStatus> runStatusMap = {
		{ "NO",  RunStatus::NO },
		{ "OK",     RunStatus::OK    },
		{ "ERR",    RunStatus::ERR   }
	};*/
	
	std::string inline to_string(const RunStatus& status)
	{
		switch(status)
		{
			case RunStatus::NO:  return "NO";  break;
			case RunStatus::OK:     return "OK";     break;
			case RunStatus::ERR:    return "ERR";    break;
		}
		return nullptr;
	}
	
	/*
	inline std::ostream &operator << (std::ostream &os, const RunStatus &status)
	{
		switch(status)
		{
			case RunStatus::TO_DO:  os << "TO_DO";  break;
			case RunStatus::OK:     os << "OK";     break;
			case RunStatus::ERR:    os << "ERR";    break;
		}
		return os;
	}
	*/
}

#endif // !RUN_STATUS_H
