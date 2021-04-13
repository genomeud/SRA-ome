# c++ code compilation
To compile the c++ code is needed:
    - c++ version >=:   c++17
    - link library:     -lstdc++fs
    - link file:        run.cpp
    - c++ compiler:     g++ | clang

NB: clang is giving error for now

so:
g++ -std=c++17 main.cpp run.cpp -lstdc++fs