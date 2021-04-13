# c++ code compilation
To compile the c++ code is needed:
* c++ version >=:   c++17
* link file:        run.cpp

NB: library <filesystem> is pretty new.
Need to link:
* using g++:
    + -lstdc++fs
* using clang++:
    + -lc++fs

NB: clang is giving error for now

so:
* g++ -std=c++17 main.cpp run.cpp -lstdc++fs
* clang++ -std=c++17 main.cpp run.cpp -lc++fs

For more see:
https://en.cppreference.com/w/cpp/filesystem
