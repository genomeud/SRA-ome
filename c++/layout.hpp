#ifndef LAYOUT_HPP
#define LAYOUT_HPP

#include <map>
#include <string>
#include <iostream>

namespace SRA {

	enum class Layout {
		SINGLE,
		PAIRED
	};

	extern std::map<std::string, Layout> layoutMap;
	/*
	extern std::map<std::string, Layout> layoutMap = {
		{ "SINGLE", Layout::SINGLE },
		{ "PAIRED", Layout::PAIRED }
	};
	*/
	std::string inline to_string(const Layout& layout) {
		switch(layout)
		{
			case Layout::SINGLE: return "SINGLE"; break;
			case Layout::PAIRED: return "PAIRED"; break;
		}
		return nullptr;
	}


}

#endif // !LAYOUT_H
