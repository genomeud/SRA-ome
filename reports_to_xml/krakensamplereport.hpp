
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

    #define NUMBER_OF_RANKS 9

    const char ranks [NUMBER_OF_RANKS] = {
        'R', //root
        'D', //domain
        'K', //kingdom
        'P', //phylum
        'C', //class
        'O', //order
        'F', //family
        'G', //genus
        'S' //species
    };

    const char unclassified_rank = 'U';
    const int unclassified_index = 0;

    
    int compare (char rankLevel1, int rankIndex1, char rankLevel2, int rankIndex2);
    int indexOf(const char * array, int n, char element);
    tuple<char, int> getRankLevelAndRankIndex(const string& rankRow);
    
    //K > C   ==> 1
    //K1 > K2 ==> 1
    //K1 = K1 ==> 0
    //G < K   ==> -1
    int compare (char rankLevel1, int rankIndex1, char rankLevel2, int rankIndex2) {
        int level1_as_int = indexOf(ranks, NUMBER_OF_RANKS, rankLevel1);
        int level2_as_int = indexOf(ranks, NUMBER_OF_RANKS, rankLevel2);
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

    int indexOf(const char * array, int n, char element) {
        if(element == unclassified_rank) return unclassified_index;
        int i = 0;
        while(i < n && array[i] != element) {
            i++;
        }
        return i < n ? i : -1;
    }

    //first char:   rank level
    //other chars:  rank index
    tuple<char, int> getRankLevelAndRankIndex(const string& rankRow) {
        char rank_lvl = rankRow.at(0);
        int rank_idx = 0;
        //check if it is valid
        if(indexOf(ranks, NUMBER_OF_RANKS, rank_lvl) < 0) {
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