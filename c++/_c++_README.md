# c++ code compilation
To compile the c++ code is needed:
* c++ version:
    + c++17
* link file:
    + run.cpp
* libraries:
    + for multi threading:
        + pthread
    + lstdc++fs (with g++) or lc++fs (with clang++) (for filesystem)

NB: clang is giving error for now

so:
* g++     main.cpp run.cpp -std=c++17 -lstdc++fs
* clang++ main.cpp run.cpp -std=c++17 -lc++fs

For more see:
https://en.cppreference.com/w/cpp/filesystem
