#include <stdio.h>
#include <iostream>
#include <algorithm>
#include <map>
#include <vector>
#include <fstream>
#include <queue>
#include <limits>
#include <iterator>
#include <utility>  
 
#define MAX_N_VERTS 1000
using namespace std;

int nWorkers[MAX_N_VERTS];
int taskDuration[MAX_N_VERTS];
int degreeIn[MAX_N_VERTS];
int degreeOut[MAX_N_VERTS];
int visited[MAX_N_VERTS];
int ES[MAX_N_VERTS];
int EF[MAX_N_VERTS];
int LF[MAX_N_VERTS];
int LS[MAX_N_VERTS];
int durMin, minW;

size_t first,last;
map <int,int>graph[MAX_N_VERTS];
map <int,int>graphT[MAX_N_VERTS]; // transposto
queue <int>q;

string line;
ifstream myfile ("data.txt");

int N_VERTS = 0;

int MinimalDuration(){
    int f=-1;
    for(int i=1;i<=N_VERTS;i++){
        if(EF[i] > f) f = EF[i];
    }
    return f;
}

void findLS(){
    for(int i = 1 ;i <=N_VERTS;i++){
        LS[i] = LF[i] - taskDuration[i];
    }
}
void getTaskNeighbours(int id){
        // get nodes from the remaining of the line :  tarefa([int1, int2], duration,workers)
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
            graphT[node][id] = 0;
            degreeIn[node]++;
            degreeOut[id]++;
            tmp.erase(0, last+1);
            last = tmp.find(",");
        }
        
        if(!tmp.empty()){
            
            node = atoi(tmp.c_str());
            graph[id][node] = 0;
            graphT[node][id] = 0;
            degreeIn[node]++;
            degreeOut[id]++;
           
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
        N_VERTS++;
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
    for(int i=1; i<=N_VERTS ;i++){
        nWorkers[i] = 0;
        taskDuration[i] = 0;
        degreeIn[i] = 0;
        visited[i] = 0;
        ES[i] = 0;
        EF[i] = 0;
        degreeOut[i] = 0;
    }
}

void findLF(){
    
    int degreeOutCopy[MAX_N_VERTS];
    copy(begin(degreeOut), end(degreeOut), begin(degreeOutCopy));
    queue<int>qu;
    map<int,int>::iterator it;
    int tmp;

    for(int i=1; i<= N_VERTS ;i++){
        LF[i] = durMin;      
    }
    for(int i=1; i<=N_VERTS ;i++){
        if(degreeOutCopy[i] == 0){
            qu.push(i);
        }
    }
  
    while(!qu.empty()){
        tmp = qu.front();
        qu.pop();
        for(it=graphT[tmp].begin();it!=graphT[tmp].end();it++){
            if(LF[it->first] > LF[tmp] - taskDuration[tmp]){
                LF[it->first] = LF[tmp] - taskDuration[tmp];
            }
            degreeOutCopy[it->first]--;
            if(degreeOutCopy[it->first] == 0) qu.push(it->first);
        }
    }

}

void findEF(){
    for(int i = 1; i<=N_VERTS;i++){
        EF[i] = ES[i] + taskDuration[i];
    }
}
void findES(){
    map<int,int>::iterator it;
    int durMin = -1;
    int corr = 0;
    int degreeInCopy[MAX_N_VERTS];
    copy(begin(degreeIn), end(degreeIn), begin(degreeInCopy));

    for(int i=1; i<=N_VERTS;i++){
        if(degreeInCopy[i] == 0){
            q.push(i);
        }
    }

    while(!q.empty()){
        int tmp;
        tmp = q.front();
        q.pop();

        if(durMin < ES[tmp]){
            durMin = ES[tmp];
        }
        for(it=graph[tmp].begin();it!=graph[tmp].end();it++){
            if(ES[it->first] < ES[tmp] + taskDuration[tmp]){
                ES[it->first] = ES[tmp] + taskDuration[tmp];
            }
            degreeInCopy[it->first]--;
            if(degreeInCopy[it->first] == 0){
                q.push(it->first);
            } 
        }

    }

}


int minWorkers(vector<int>nodes){
    int delta = -1;
    int newDelta = 0;
    int firstToFinish;
    vector<int>currentTasks;
    map<int,int>::iterator it;

    int size;
    
     for(int i=0; i<nodes.size();i++){
         if(degreeIn[nodes[i]] == 0){
             currentTasks.push_back(nodes[i]);
             visited[nodes[i]] = 1;
         }
     }

    while(currentTasks.size() > 0){
        firstToFinish = INT_MAX;
        for(int i=0; i<currentTasks.size() ;i++){
            if(EF[currentTasks[i]] < firstToFinish) firstToFinish = EF[currentTasks[i]];
        }
        // calculate nWorkers 
        newDelta = 0;
        for(int i=0;i<currentTasks.size();i++){
            newDelta += nWorkers[currentTasks[i]]; 
        }
        if(delta < newDelta){
            delta = newDelta;
        }

        size = currentTasks.size();
        for(int i=0; i<size ;i++){
            if(EF[currentTasks[i]] == firstToFinish){
                // verificar quais filhos tem ES = firstToFinish, atualizar lista
                for(it=graph[currentTasks[i]].begin();it!=graph[currentTasks[i]].end();it++){
                    if(!visited[it->first] && (ES[it->first] == firstToFinish)){
                        visited[it->first] = 1;
                        currentTasks.push_back(it->first);
                    }
                }
                // tirar currentTasks[i] de currentTasks
                currentTasks.erase(currentTasks.begin()+i);
                size = size-1;
                i--;
                
            }   
        } 
       
    }
    
    return delta;

}

int minWorkersCritical(){
    vector<int>nodes;
    int ret;
    for(int i=1;i<=N_VERTS;i++){
        if(LS[i] == ES[i]){
            nodes.push_back(i);
        }
    }
    return minWorkers(nodes);
}
/*  
    The consistency check is one part of TtEf propagation that checks whether
there is a resource overload in any task interval.

The cumulative resource scheduling problem is inconsistent if
R · (lctb − esta) − energy(a, b) < 0

by iterating over the end times in decreasing order we can calculate the minimal available
free energy minAvail from the previous iteration. If the reduction in this free
energy for the next iteration cannot make it negative we know that none of the
task intervals in this iteration can lead to resource overload, and we can skip
the entire set of task intervals




Activity i is specified by its start time Si, its processing time pi, its resource usage ri,
and its energy ei:= pi*ri


bool checkIfNWorkersPossible(int nWorkers, vector<pair<int,int> > sortedActivitiesByES, vector <pair<int,int> > sortedActivitiesByLF){
    double end = std::numeric_limits<double>::infinity();
    double minAvail = std::numeric_limits<double>::infinity();
    int tmpLF, E,tmpES;
    for(int y = N_VERTS-1; i>=0;i--){
        tmpLF = sortedActivitiesByLF[y];
        if(LF[tmpLF] == end) continue;
        if(end != numeric_limits<double>::infinity() 
        && minAvail != numeric_limits<double>::infinity() 
        &&  minAvail >= nWorkers * (end-LF[tmpLF]) - ttAfter[LF[tmpLF]] + ttAfter[end]) continue;
        end = LF[tmpLF];
        E = 0;
        minAvail = std::numeric_limits<double>::infinity();
        for(int x = N_VERTS-1;i>=0;i++){
            tmpES = sortedActivitiesByES[x];
            if(end <= ES[tmpES]) continue;
            inicio = ES[tmpES];
            if(LF[tmpES] <= end ){
                E = E + eiEF[tmpES];
            }
            else if(LF[tmpES] - piEF[tmpES] < end){
                E = E + ri[tmpES]*(end-(LF[tmpES - piEF[tmpES]]));
                avail = nWorkers*(end-inicio)-E-(ttAfter[ES[tmpES]]-ttAfter[LF[tmpLF]]);
            }
            if(avail < 0){
                return false;
            }
            if(avail < minAvail) minAvail = avail;
        }
    }
    return true;
}
*/
int main (){

    int minWCri;
    vector<int> allTasks;
    vector<pair<int,int> > sortedActivitiesByES; // ES, index of activity
    vector<pair<int,int> > sortedActivitiesByLF; // LF, index of activity
    

    resetDataStructures();
    readData();
    findES(); 
    findEF();
    
    durMin = MinimalDuration();
    findLF(); // uses durMin (needs to be after MinimalDuration)
    findLS();
    for(int i=1; i<= N_VERTS;i++){
        allTasks.push_back(i);
        cout << "LF[" << i << "]: " << LF[i];
        cout << "| LS[" << i << "]: " << LS[i];
        cout << "| EF[" << i << "]: " << EF[i];
        cout << "| ES[" << i << "]: " << ES[i] << endl;
          

    }
    cout << "Duração mínima do projeto: "<< durMin << endl;
    minW = minWorkers(allTasks); 
    cout << "Número mínimo de trabalhadores com ES's fixados: "<< minW << endl;
    minWCri= minWorkersCritical();
    cout << "Número mínimo de trabalhadores para atividades críticas: "<< minWCri << endl;

    for(int i = 1;i <= N_VERTS;i++){
        sortedActivitiesByES.push_back(make_pair(ES[i], i));
        sortedActivitiesByLF.push_back(make_pair(LF[i], i));
    }
    sort(sortedActivitiesByES.begin(),sortedActivitiesByES.end());
    sort(sortedActivitiesByLF.begin(),sortedActivitiesByLF.end());
   
    for(int possibleNWorkers = minWCri; possibleNWorkers<= minW; possibleNWorkers++){
       /* if(checkIfNWorkersPossible(possibleNWorkers,sortedActivitiesByES,sortedActivitiesByLF)){
            cout << "Número mínimo de trabalhadores sem ES's fixados: " << possibleNWorkers << endl;
            break;
        }
        */
    }
    


    return 0;
}