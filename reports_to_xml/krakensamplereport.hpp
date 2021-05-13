
#ifndef KRAKEN_SAMPLE_REPORT_H
#define KRAKEN_SAMPLE_REPORT_H

#include <string>
#include <iostream>
#include <fstream>
#include <utility>
#include <vector>
#include <tuple>

#define OUT

using namespace std;

namespace krakensamplereport {

    //indexes of columns in file 'run.kraken.report.txt'
    const int IDX_OF__PERC_FRAGMENTS_ROOTED      = 0;
    const int IDX_OF__NUM_OF_FRAGMENTS_ROOTED    = 1;
    const int IDX_OF__NUM_OF_FRAGMENTS_DIRECT    = 2;
    const int IDX_OF__RANK_CODE                  = 3;
    const int IDX_OF__TAX_ID                     = 4;
    const int IDX_OF__SCIENTIFIC_NAME            = 5;

    const vector<string> fields = {
        "PERC_FRAGS_ROOTED",
        "NUM_OF_FRAGS_ROOTED",
        "NUM_OF_FRAGS_DIRECT",
        "RANK",
        "TAX_ID",
        "SCIENTIFIC_NAME"
    };

    //<tree_position, char, name>
    const vector<tuple<int, char, string>> ranks = {
        std::make_tuple(0, 'U', "UNCLASSIFIED"),
        std::make_tuple(0, 'R', "ROOT"),
        std::make_tuple(1, 'D', "DOMAIN"),
        std::make_tuple(2, 'K', "KINGDOM"),
        std::make_tuple(3, 'P', "PHYLUM"),
        std::make_tuple(4, 'C', "CLASS"),
        std::make_tuple(5, 'O', "ORDER"),
        std::make_tuple(6, 'F', "FAMILY"),
        std::make_tuple(7, 'G', "GENUS"),
        std::make_tuple(8, 'S', "SPECIES")
    };
    
    int compare (char rankLevel1, int rankIndex1, char rankLevel2, int rankIndex2);
    int indexOf(const char * array, int n, char element);
    tuple<char, int> getRankLevelAndRankIndex(const string& rankRow);
    int getRankImportanceFromRankChar(char element);
    string getRankNameFromRankChar(char element);
    
    //K > C   ==> 1
    //K1 > K2 ==> 1
    //K1 = K1 ==> 0
    //G < K   ==> -1
    int compare (char rankLevel1, int rankIndex1, char rankLevel2, int rankIndex2) {
        int level1_as_int = getRankImportanceFromRankChar(rankLevel1);
        int level2_as_int = getRankImportanceFromRankChar(rankLevel2);
        if(level1_as_int == -1 || level2_as_int == -1) {
            cout << "error in rank\n";
            return -2;
        }
        if (level1_as_int == level2_as_int) {
            if (rankIndex1 < rankIndex2)       return 1;
            else if (rankIndex1 == rankIndex2) return 0;
            else                               return -1;
        } else if (level1_as_int < level2_as_int) {
            return 1;  
        } else {
            return -1;
        }
    }

    int getRankImportanceFromRankChar(char element) {
        for (int i = 0; i < ranks.size(); i++) {
            if (element == std::get<1>(ranks.at(i))) {
                return std::get<0>(ranks.at(i));
            }
        }
        return -1;
    }
    
    string getRankNameFromRankChar(char element) {
        for (int i = 0; i < ranks.size(); i++) {
            if (element == std::get<1>(ranks.at(i))) {
                return std::get<2>(ranks.at(i));
            }
        }
        return nullptr;
    }

    //first char:   rank level
    //other chars:  rank index
    tuple<char, int> getRankLevelAndRankIndex(const string& rankRow) {
        char rank_lvl = rankRow.at(0);
        int rank_idx = 0;
        //check if it is valid
        if(getRankImportanceFromRankChar(rank_lvl) < 0) {
            cout << "error in rank\n";
            return std::make_tuple(-1, -1);
        }
        if (rankRow.size() > 1) {
            rank_idx = atoi(rankRow.substr(1).c_str());
        }
        return std::make_tuple(rank_lvl, rank_idx);
    }
    
}

#endif