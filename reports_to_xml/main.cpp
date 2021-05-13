//other useful
#include <string>
#include <vector>
//to read and write on stdin/stderr
#include <iostream>
//to read and write on files
#include <fstream>
#include <sstream>
#include <tuple>
#include "krakensamplereport.hpp"

using namespace std;

#define OUT

vector<string> split(const string& line, char delim);
int removeStartingCharacters(string& line, char toRemove);
//string rkLevel_rkIndex_NameToString(char rank_level, int rank_index, const string& name);
string XML_Header(const string& line);
string XML_Trailer(const string& line);
string buildElementForXML(char rank_lvl, int rank_idx, char separator, int nOfSeparators, bool header);
string buildDataForXML(const vector<string>& values, char separator, int nOfSeparators);
void addSeparators(char separator, int nOfSeparators, string &output);
void convertKrakenSampleReportFromTxtToXML(ifstream & runs_ifs, char outputFileDelimiter, OUT string& output);

const string XML_ROOT = "REPORT";

int main(int argc, char *argv[]) {

    char delimiter = '\t';

    const int nOfParamsNeeded = 1;

    string reportFileInput_path;
    string reportFileOutput_path;

    //check params
    if (argc != nOfParamsNeeded + 1) {
        cout << "usage: " << argv[0] << " <reportFileInput>\n";
        return 1;
    } else {
        reportFileInput_path = argv[1];
        reportFileOutput_path = reportFileInput_path + ".xml";
    }
    
    string output = "";
    

    //convert string path to char* path
    const char * path = reportFileInput_path.c_str();

    //open file in read mode
    ifstream runs_ifs(path);

    //check if it is open
    if (!runs_ifs.is_open()) {
        cout << "Error: cannot open input file\n";
        return 2;
    }

    convertKrakenSampleReportFromTxtToXML(runs_ifs, ' ', output);

    runs_ifs.close();

    ofstream file_ofs(reportFileOutput_path);
    if (!file_ofs.is_open()) {
        cout << "Error: cannot open output file\n";
        return 3;
    }

    file_ofs << output;

    file_ofs.close();

    cout << "Done, output printed to: " << reportFileOutput_path << "\n";

    return 0;
}

string XML_Header(const string& line) {
    return "<" + line + ">";
}

string XML_Trailer(const string& line) {
    return "</" + line + ">";
}

/*
string rkLevel_rkIndex_NameToString(char rank_level, int rank_index, const string& name) {
    string output = "";
    output += rank_level;
    if(rank_index > 0) output += std::to_string(rank_index);
    output += ": ";
    output += name;
    return output;
}
*/

int removeStartingCharacters(string& line, char toRemove) {
    int count = -1;
    int n = line.size();
    while(count < n && line.at(++count) == toRemove);
    line = line.substr(count);
    return count;
}

vector<string> split(const string& line, char delim) {
    vector<string> result;
    istringstream iss(line);
    for (string token; getline(iss, token, delim);) {
        result.push_back(move(token));
    }
    return result;
}

void addSeparators(char separator, int nOfSeparators, string &output) {
    for(int i = 0; i < nOfSeparators; i++) {
        output += separator;
    }
}

string buildElementForXML(char rank_lvl, int rank_idx, char separator, int nOfSeparators, bool header) {
    string output = "";
    addSeparators(separator, nOfSeparators, output);
    //string raw = rkLevel_rkIndex_NameToString(rank_lvl, rank_idx, name);
    string raw = krakensamplereport::getRankNameFromRankChar(rank_lvl);
    if(header) {
        output += XML_Header(raw);
    } else {
        output += XML_Trailer(raw);
    }
    output += "\n";
    return output;
}

string buildDataForXML(const vector<string>& values, char separator, int nOfSeparators) {
    string output = "";
    string dataXML = "DATA";
    string dataXMLTag = XML_Header(dataXML);
    addSeparators(separator, nOfSeparators, output);
    output += dataXMLTag + "\n";

    for (int i = 0; i < values.size(); i++) {
        addSeparators(separator, nOfSeparators + 1, output);
        string data = krakensamplereport::fields.at(i);
        output += XML_Header(data) + values.at(i) + XML_Trailer(data) + "\n";
    }
    dataXMLTag = XML_Trailer(dataXML);
    addSeparators(separator, nOfSeparators, output);
    output += dataXMLTag + "\n";
    return output;
}

//output string is passed as output reference parameter (for efficiency reason, can be very big)
void convertKrakenSampleReportFromTxtToXML(ifstream & runs_ifs, char outputFileDelimiter, OUT string& output) {
    
    output = XML_Header(XML_ROOT) + "\n";

    char inputFileFieldsDelimiter = '\t';
    char inputFileTreeDelimiter = ' ';

    //example:
    /*
        0.52	16121	16121	U	0	    unclassified
        99.48	3071216	77616	R	1	    root
        88.19	2722839	309	    R1	131567	  cellular organisms
        87.99	2716684	0	    D	2759	    Eukaryota
    */

    string raw_line;

    //all parents of the current line
    //vector using push_back() and pop_back() represents a stack: (LIFO politic)
    //<rank_lvl, rank_idx, num_spaces>
    vector<tuple<char, int, int>> parents;

    while (getline(runs_ifs, raw_line)) {

        int idx;

        //split line in a vector of string
        vector<string> line = split(raw_line, inputFileFieldsDelimiter);

        //remove starting white spaces form percentage_fragments field and update vector
        idx = krakensamplereport::IDX_OF__PERC_FRAGMENTS_ROOTED;
        string percFragsRooted_str = line.at(idx);
        removeStartingCharacters(percFragsRooted_str, inputFileTreeDelimiter);
        line[idx] = percFragsRooted_str;

        //get rank level and rank index (useful for algorithm)
        idx = krakensamplereport::IDX_OF__RANK_CODE;
        string rank_cur_row = line.at(idx);
        tuple<char, int> rank_cur_tuple = krakensamplereport::getRankLevelAndRankIndex(rank_cur_row);
        char rank_lvl_cur = std::get<0>(rank_cur_tuple);
        int rank_idx_cur = std::get<1>(rank_cur_tuple);

        //remove starting white spaces form scientific_name field and update vector
        idx = krakensamplereport::IDX_OF__SCIENTIFIC_NAME;
        string name_cur = line.at(idx);
        //num_spaces_cur very important: is used to define the tree!
        int num_spaces_cur = removeStartingCharacters(name_cur, inputFileTreeDelimiter);
        line[idx] = name_cur;

        //start of real algorithm
        if (parents.size() > 0) {

            bool isChild;
            do {
                //get last element, check if it is a parent of the current line
                tuple<char, int, int> parent = parents.back();
                
                char rank_lvl_prec = std::get<0>(parent);
                int rank_idx_prec = std::get<1>(parent);
                int num_spaces_prec = std::get<2>(parent);

                //sometimes fails, for example in this case:
                /*
                    4.58	141441	0	    R1	2787854	  other entries
                    4.58	141441	141441	R2	28384	    other sequences
                    4.19	129320	0	    D	10239	  Viruses
                */
                /*
                compareCurAndPrecRank = krakensamplereport::compare(
                    rank_lvl_prec, rank_idx_prec, rank_lvl_cur, rank_idx_cur
                );
                */

                //if num_spaces_cur > num_spaces_prec ==> child in the tax tree
                isChild = num_spaces_prec < num_spaces_cur;

                if(!isChild) {
                    //remove last element from parents, it is not a parent anymore
                    parents.pop_back();
                    
                    //print xml trailer of the removed parent
                    output += buildElementForXML(
                        rank_lvl_prec,
                        rank_idx_prec,
                        outputFileDelimiter,
                        parents.size() + 1,
                        false
                    );
                }

            } while(!isChild && parents.size() > 0);

        }

        //add current line as a possible parent for next line         
        tuple<char, int, int> current = std::make_tuple(
            rank_lvl_cur, rank_idx_cur, num_spaces_cur
        );
    
        output += buildElementForXML(
            rank_lvl_cur,
            rank_idx_cur,
            outputFileDelimiter,
            parents.size() + 1,
            true
        );

        output += buildDataForXML(
            line, outputFileDelimiter, 
            parents.size() + 2
        );
        
        parents.push_back(current);

    }

    while(parents.size() > 0) {
        //print remaining parents
        tuple<char, int, int> parent = parents.back();
        parents.pop_back();
        
        output += buildElementForXML(
            std::get<0>(parent),
            std::get<1>(parent),
            outputFileDelimiter,
            parents.size() + 1,
            false
        );
    }

    output += XML_Trailer(XML_ROOT) + "\n";
}