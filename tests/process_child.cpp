#include <cstdio>
#include <cstring>
#include <thread>
#include <chrono>
int main(int argc,char ** argv) {
    if(argc>1 && !std::strcmp(argv[1],"wait")) {std::this_thread::sleep_for(std::chrono::seconds(20));return 8;}
    if(argc>1 && !std::strcmp(argv[1],"echo")) {char line[128];if(std::fgets(line,sizeof(line),stdin))std::fputs(line,stdout);return 7;}
    if(argc>1 && !std::strcmp(argv[1],"args")) {
        if(argc!=3 || std::strcmp(argv[2],"two words \"quoted\""))return 39;
        std::fputs("argv-ok",stdout);return 7;
    }
    std::fputs("process-ok",stdout);return 7;
}
