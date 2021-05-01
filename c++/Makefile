#NB do NOT put any spaces after definition of CXX
#else the ifeq condition will fail

#if use g++
CXX=g++
#if use clang
#CXX=clang

CPPFLAGS_FOR_ALL = -g -std=c++17
CPPFLAGS_FOR_BOOST = -I/home/fzuccato/boost/boost_1_76_0 -DBOOST_LOG_DYN_LINK

CPPFLAGS_FOR_RUNCPP = $(CPPFLAGS_FOR_ALL)
CPPFLAGS_FOR_MAINCPP = $(CPPFLAGS_FOR_ALL) $(CPPFLAGS_FOR_BOOST)
CPPFLAGS_FOR_BOOSTLOGGERCPP = $(CPPFLAGS_FOR_ALL) $(CPPFLAGS_FOR_BOOST)

LDFLAGS = -g -L/home/fzuccato/boost/boost_1_76_0/stage/lib

LDLIBS_FOR_ALL = -pthread -lboost_log -lpthread -lboost_log_setup -lboost_filesystem -lboost_thread
LDLIBS_FS_GPP = -lstdc++fs #if use g++
LDLIBS_FS_CLANG = -lstdc++ #if use clang
LDLIBS = $(LDLIBS_FOR_ALL)

ifeq ($(CXX),g++)
	LDLIBS += $(LDLIBS_FS_GPP)
else ifeq ($(CXX),clang)
	LDLIBS += $(LDLIBS_FS_CLANG)
else
#no idea what library is needed to compile with filesystem
endif

main.out: run.o main.o boost_logger.o
	$(CXX) $(LDFLAGS) run.o main.o boost_logger.o -o main.out $(LDLIBS)
boost_logger.o: boost_logger.hpp boost_logger.cpp
	$(CXX) $(CPPFLAGS_FOR_BOOSTLOGGERCPP) -c boost_logger.cpp -o boost_logger.o
run.o: run.hpp run.cpp
	$(CXX) $(CPPFLAGS_FOR_RUNCPP) -c run.cpp -o run.o	
main.o: sra.hpp main.cpp 
	$(CXX) $(CPPFLAGS_FOR_MAINCPP) -c main.cpp -o main.o

#Header inclusions:
#"sra.hpp" includes "run.hpp"
#"run.hpp" includes "runstatus.hpp" "layout.hpp"