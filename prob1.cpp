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
#define CASE_CRIT 1
#define CASE_ALL_TASKS 2
using namespace std;

int nWorkers[MAX_N_VERTS];
int taskDuration[MAX_N_VERTS];
int degreeIn[MAX_N_VERTS];
int degreeOut[MAX_N_VERTS];
int visited[MAX_N_VERTS];
int ES[MAX_N_VERTS];    //earliest start
int EF[MAX_N_VERTS];  //earliest finish
int LF[MAX_N_VERTS]; // latest finish
int LS[MAX_N_VERTS]; // latest start
int piEF[MAX_N_VERTS]; //processing time of the free part) for each activity pi - piTT
int piTT[MAX_N_VERTS]; //Fixed part of an activity i (length of its compulsory part , max(0 , EF[i] - LS[i]))
int eiEF[MAX_N_VERTS]; // free energy 
int eiTT[MAX_N_VERTS]; // fixed energy
int durMin, minW;

size_t first,last;
map <int,int>graph[MAX_N_VERTS];
map <int,int>graphT[MAX_N_VERTS]; // transposto
queue <int>q;

string line;
ifstream myfile ("data.txt");

int N_VERTS = 0;


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
        // for each child checks if ES[child] < ES[father] + duration[father]
        //if so, updates ES[child]
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

// returns the maximum of all earliest finishes = minimal duration
// assumes that ES is already available
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

// CASE_CRIT for when we only look for critical tasks
// CASE_ALL_TASKS for when we look for all tasks, with no restrictions
int minWorkers(vector<int>nodes, int cases){ 
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
                        switch (cases){
                        case CASE_CRIT:
                            if(ES[it->first] == LS[it->first]){
                                visited[it->first] = 1;
                                currentTasks.push_back(it->first);
                            }
                            break;
                        case CASE_ALL_TASKS:
                            visited[it->first] = 1;
                            currentTasks.push_back(it->first); 
                        default:
                            break;
                        }
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

//pushes only critical tasks to the vector nodes
int minWorkersCritical(){
    vector<int>nodes;
    for(int i = 1; i<=N_VERTS;i++){
        visited[i] = 0;
    }
    for(int i=1;i<=N_VERTS;i++){
        if(LS[i] == ES[i]){
            nodes.push_back(i);
        }
    }
    return minWorkers(nodes, CASE_CRIT);
}
/*  

Based on the paper "Explaining Time-Table-Edge-Finding Propagation for the Cumulative Resource Constraint" 
    by Andreas Schutt, Thibaut Feydy, and Peter J. Stuckey

The consistency check is one part of TtEf propagation that checks whether
there is a resource overload in any task interval.
The cumulative resource scheduling problem is inconsistent if

    R · (lctb − esta) − energy(a, b) < 0

by iterating over the end times in decreasing order we can calculate the minimal available
free energy minAvail from the previous iteration. If the reduction in this free
energy for the next iteration cannot make it negative we know that none of the
task intervals in this iteration can lead to resource overload, and we can skip
the entire set of task intervals

Activity i is specified by its start time Si, its processing time pi (duration), its resource usage ri (workers),
and its energy ei:= pi*ri .
The algorithm iterates on each end time in decreasing order. For each end
time the algorithm first checks if no propagation is possible with this end time:

        if(end != numeric_limits<double>::infinity() 
        && minAvail != numeric_limits<double>::infinity() 
        &&  minAvail >= nWorkers * (end-LF[tmpLF]) - ttAfter[LF[tmpLF]] + ttAfter[end]) continue;

and if so skips to the next. Otherwise it examines each possible
start time, updating the free energy used E for the new task interval
and calculating the energy available avail in the task interval:

         if(LF[tmpES] <= end ){
            E = E + eiEF[tmpES];
        }
        else if(LF[tmpES] - piEF[tmpES] < end){
            E = E + ri[tmpES]*(end-(LF[tmpES]- piEF[tmpES]));
            avail = nWorkers*(end-inicio)-E-(ttAfter[ES[tmpES]]-ttAfter[LF[tmpLF]]);
        }

If this is negative it explains the overload in the interval and returns false. If not
it updates the minimum available energy and examines the next task interval:

        if(avail < minAvail) minAvail = avail;
*/

 
bool checkIfNWorkersPossible(int possibleWorkers, vector<pair<int,int> > sortedActivitiesByES, vector <pair<int,int> > sortedActivitiesByLF, double* ttAfter){
    double end = std::numeric_limits<double>::infinity();
    double minAvail = std::numeric_limits<double>::infinity();
    double avail;
    int tmpLF, E,tmpES, inicio;
    


    for(int y = N_VERTS-1; y>=0;y--){
        tmpLF = sortedActivitiesByLF[y].second;
        if(LF[tmpLF] == end) continue;
        if(end != numeric_limits<double>::infinity() 
        && minAvail != numeric_limits<double>::infinity() 
        &&  (minAvail >= (possibleWorkers * (end-LF[tmpLF]) - ttAfter[LF[tmpLF]] + ttAfter[(int) end]))) continue;
        
        end = LF[tmpLF];
        E = 0;
        minAvail = std::numeric_limits<double>::infinity();
        for(int x = N_VERTS-1;x>=0;x--){
           
            tmpES = sortedActivitiesByES[x].second;
            if(end <= ES[tmpES]) continue;
            inicio = ES[tmpES];
            if(LF[tmpES] <= end ){
                E = E + eiEF[tmpES];
                
            }
            else if(LF[tmpES] - piEF[tmpES] < end){
             
                E = E + nWorkers[tmpES]*(end-(LF[tmpES]- piEF[tmpES]));
                avail = (possibleWorkers*(end-inicio)) - E - (ttAfter[ES[tmpES]]-ttAfter[LF[tmpLF]]);
            }
            if(avail < 0){
                return false;
            }
            if(avail < minAvail) minAvail = avail;
            
        }
    }
    return true;
}

// uses brute force approach to discover min possible numbers of workers without fixing any date for the tasks
// and without making the project finish late

bool bruteForceCheckNWorkers(int n,vector<pair<int,int> >sortedActivitiesByEs, int lowerBound[], int upperBound[], int currentNWorkers[], int minNWorkers){
    bool stillPossible = false, ret=false;
    int tmpActivity;
    int newLowerBound[MAX_N_VERTS];
    map <int,int>::iterator it;

    if(n == N_VERTS){
        return true;
    }    
    //we first get the activity that has the lower ES
    tmpActivity = sortedActivitiesByEs[n].second;

    // we look at every possible start time for this activity
    // and check if with this start time its possible to find a solution that
    // uses no more than minNWorkers workers
    for(int tmpDate=lowerBound[tmpActivity];tmpDate<=upperBound[tmpActivity];tmpDate++){
        stillPossible = true;
        for(int k=1;k<=N_VERTS;k++){
            newLowerBound[k] = lowerBound[k];
        }
        
        // new date for a task, must update start times for all children
        for(it=graph[tmpActivity].begin();it!=graph[tmpActivity].end();it++){
            newLowerBound[it->first] = max(newLowerBound[it->first], tmpDate+taskDuration[tmpActivity]);
        }
        // update number of workers used for each interval that this activity occurs
        for (int j= tmpDate; j < tmpDate+taskDuration[tmpActivity]; j++){
            currentNWorkers[j] += nWorkers[tmpActivity];
            //if we get more workers than the bound we set earlier, we know that
            //the start time we set for the activity is not valid
            if(currentNWorkers[j] > minNWorkers){
                stillPossible = false;
            }    
        }
        

        if(stillPossible){
            // recursive for the next task
            if(bruteForceCheckNWorkers(n+1, sortedActivitiesByEs, newLowerBound, upperBound, currentNWorkers, minNWorkers)){
                ret = true;
            }
        }
        
        // erase workers
        //so we are to check with different start times
        for (int j= tmpDate; j < tmpDate+taskDuration[tmpActivity]; j++){
            currentNWorkers[j] -= nWorkers[tmpActivity];
        }
        
    }
    return ret;
}
 
int main (){

    int minWCri;
    vector<int> allTasks;
    vector<pair<int,int> > sortedActivitiesByES; // ES, index of activity
    vector<pair<int,int> > sortedActivitiesByLF; // LF, index of activity
    double *ttAfter;
    bool res = false;
    int currentNWorkers[MAX_N_VERTS];    

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
    minW = minWorkers(allTasks, CASE_ALL_TASKS); 
    cout << "Número mínimo de trabalhadores com ES's fixados: "<< minW << endl;
    minWCri = minWorkersCritical();
    cout << "Número mínimo de trabalhadores para atividades críticas: "<< minWCri << endl;

    for(int i = 1;i <= N_VERTS;i++){
        sortedActivitiesByES.push_back(make_pair(ES[i], i));
        sortedActivitiesByLF.push_back(make_pair(LF[i], i));
    }
    sort(sortedActivitiesByES.begin(),sortedActivitiesByES.end());
    sort(sortedActivitiesByLF.begin(),sortedActivitiesByLF.end());

    // calculate piEF (processing time of the free part) for each activity pi - piTT, 
    // where piTT = Fixed part of an activity i (length of its compulsory part , max(0 , EF[i] - LS[i]))
    
     // calculate eiEF where free energy of eiEF i = ei - eiTT
    // where eiTT = ri * piTT
/*
    
    for(int i=1; i<= N_VERTS;i++){
        piTT[i] = max(0, EF[i]-LS[i]);
        piEF[i] = taskDuration[i] - piTT[i];
        eiTT[i] = nWorkers[i] * piTT[i];
        eiEF[i] = (nWorkers[i] * taskDuration[i]) - eiTT[i];
    }
*/
    ttAfter = (double *)malloc((durMin+2)*sizeof(double));
    // calculate ttAfter
    
    for(int i = 0; i<=durMin;i++){
        ttAfter[i] = 0;
        currentNWorkers[i] = 0;
    }
    
   /*
    for(int i = 0; i<= durMin; i++){
        for(int j = i; j<=durMin;j++){
            for(int k = 1; k<=N_VERTS;k++){
                if(j >= LS[k] && j < EF[k]){
                    ttAfter[i] += nWorkers[k];
                }
            }
        }
        
    }

   */ 

    
    for(int possibleNWorkers = minWCri; possibleNWorkers<= minW; possibleNWorkers++){
        /*
       if(checkIfNWorkersPossible(possibleNWorkers,sortedActivitiesByES,sortedActivitiesByLF, ttAfter)){
            cout << "Número mínimo de trabalhadores sem ES's fixados: " << possibleNWorkers << endl;
            break;
        }
        */
    
       if(bruteForceCheckNWorkers(0,sortedActivitiesByES, ES, LS, currentNWorkers , possibleNWorkers)){
            cout << "Número mínimo de trabalhadores sem ES's fixados: " << possibleNWorkers << endl;
            break;
       }
    }
    
    

    return 0;
}