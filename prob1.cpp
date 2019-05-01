#include <stdio.h>
#include <stdio.h>
#include <iostream>
#include <algorithm>
#include <map>
#include <vector>
#include <fstream>
 
#define N_VERTS 1000 
using namespace std;

int nWorkers[N_VERTS];
int taskDuration[N_VERTS];
int degreeIn[N_VERTS];
int visited[N_VERTS];


size_t first,last;
map <int,int>graph[N_VERTS];

string line;
ifstream myfile ("data.txt");

void getTaskNeighbours(int id){
        // get nodes from the remaining of the line :  tarefa([int1, int2], duration,workers)
        cout << line << endl;
        int node;
        string tmp, precs;
        //get the precedences between []
        first = line.find("[");
        last = line.find("]");
        tmp = line.substr(first+1, last-first-1);
        line.erase(first, last-first+2); // erase the precedences from the line

        // treat the precedences [int1,int2,int3] and create graph
        last = tmp.find(",");
        while(last != string::npos){
            precs = tmp.substr(0,last);
            node = atoi(precs.c_str());
            graph[id][node] = 0;
            degreeIn[node]++;
            tmp.erase(0, last+1);
            last = tmp.find(",");
        }
        
        if(!tmp.empty()){
            node = atoi(tmp.c_str());
            cout << node << endl;
            graph[id][node] = 0;
            degreeIn[node]++;
        }

    
       
}

void getTaskDuration(int id){
    // get task furation from the remaining of the line :  tarefa(duration,workers)
    string tmp;
    int duration;
    last = line.find(",");
    tmp = line.substr(1, last-1);
    line.erase(1, last);
    duration = atoi (tmp.c_str());
    taskDuration[id] = duration;
}
void getnWorkers(int id){
    // get number of Workers from the remaining of the line :  tarefa(workers)
    string tmp;
    int workers;
    last = line.find(")");
    tmp = line.substr(1, last-1);
    workers = atoi (tmp.c_str());
    nWorkers[id] = workers;

}
void readData(){
    string tmp;
    int id;
    if(!myfile.is_open()) {
      perror("Error open");
      exit(EXIT_FAILURE);
    }
    // each line has the following pattern
    // tarefa(taskID,listOfPrecs, duration, nWorkers)
    // listOfPrecs example : [2,5,7]

    while(getline(myfile, line)) {
        //erase tarefa
        last = line.find("(");
        line.erase(0, last);
        // get task id
        last = line.find(",");
        tmp = line.substr(1,last);
        line.erase(1, last);
        id = atoi(tmp.c_str());
        getTaskNeighbours(id); // creates the graph
        getTaskDuration(id);    // updates taskDuration[id]
        getnWorkers(id);    // updates nWorkers[id] 
    }
}

void resetDataStructures(){
    for(int i=0; i<N_VERTS ;i++){
        nWorkers[i] = 0;
        taskDuration[i] = 0;
        degreeIn[i] = 0;
        visited[i] = 0;
    }
}

int main (){
    resetDataStructures();
    readData();
    return 0;
}