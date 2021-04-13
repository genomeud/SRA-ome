# c++ code compilation
To compile the c++ code is needed:
* c++ version:
    + c++17
* link file:
    + run.cpp
* libraries:
    + for multi threading:
        + pthread
    + for filesystem:
        + lstdc++fs (with g++) or 
        + lc++fs (with clang++)

NB: filesystem is pretty new, clang is giving error to me for now

so:
* g++     main.cpp run.cpp -std=c++17 -pthread -lstdc++fs
* clang++ main.cpp run.cpp -std=c++17 -pthread -lc++fs

For more see:
https://en.cppreference.com/w/cpp/filesystem
