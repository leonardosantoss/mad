:-lib(ic).
:-lib(ic_edge_finder).
:-lib(branch_and_bound).
% :-lib(util).

% (OK) Qual é a duração mínima do projeto?

% (OK) Quantos trabalhadores são necessários se todas as tarefas tiverem início na sua data de início
% mais próxima?

% (OK) Quantos trabalhadores são necessários no mínimo para realizar as tarefas críticas?

% (OK) Qual o número mínimo de trabalhadores a contratar? Quando é que cada tarefa tem início?

% Existem soluções ótimas alternativas?

go(Dados):-
    compile(Dados),

    findall(TaskID, tarefa(TaskID,_,_,_), TasksID_),
    sort(TasksID_, TasksID),
    length(TasksID, N),

    getDurationsAndWorkers(TasksID, Durations, Workers),
    getMaxDurationAndMaxWorkers(Durations, Workers, MaxConcl, MaxWorkers),

    length(StartDates, N),

    Concl :: 0..MaxConcl,
    StartDates :: 0..MaxConcl,

    MinWorkers :: 0..MaxWorkers,
    MinWorkersES :: 0..MaxWorkers,
    MinWorkersCrit :: 0..MaxWorkers,

    prec_constrs(TasksID_, StartDates, Concl),
    get_min(Concl, Concl),

    write('Concl: '),
    writeln(Concl),

    getES(StartDates, ES),
    getLS(StartDates, LS),

    write('ES: '),
    writeln(ES),

    write('LS: '),
    writeln(LS),

    cumulative(ES, Durations, Workers, MinWorkersES),
    get_min(MinWorkersES, MinWorkersES),

    write('MinWorkersES: '),
    writeln(MinWorkersES),

    getCriticalTasks(ES,LS,TasksID,CritID),

    get_critDados(ES, CritID, CritDur, CritWorkers, CritES),

    cumulative(CritES, CritDur, CritWorkers, MinWorkersCrit),
    get_min(MinWorkersCrit, MinWorkersCrit),

    write('MinWorkersCritPath: '),
    writeln(MinWorkersCrit),

    % write('StartDate: '),
    % writeln(StartDates),

    term_variables([MinWorkers, StartDates], Vars),
    cumulative(StartDates, Durations, Workers, MinWorkers),
    % get_min(MinWorkers, MinWorkers),
    labeling(Vars),
    
    get_min(MinWorkers, MinWorkers_),
    write('MinWorkers(ConditionFree): '),
    writeln(MinWorkers_),
    
    % findfirstn(2, StartDates, labeling(Vars), Instances),
    % length(Instances,NSols),
    % write('Unique Solution? '),
    % (NSols>1,!,write('False');write('True')),nl,
    % write(Instances),nl


    write('StartDate: '),
    writeln(StartDates),!
    .


get_critDados(_,[],[],[],[]).
get_critDados(ES,[ID|CritID], [CD|CritDur], [W|Workers], [ESi|CritES]):-
    tarefa(ID,_,CD,W),
    element(ID,ES,ESi),
    get_critDados(ES, CritID, CritDur, Workers, CritES).

getCriticalTasks(_,_,[],[]).
getCriticalTasks(ES,LS,[Taski|Tars], [Taski|IDs]):-
    element(Taski, ES, ESi),
    element(Taski, LS, LSi),
    ESi#=LSi,
    getCriticalTasks(ES, LS, Tars, IDs),!.
getCriticalTasks(ES, LS, [_|Tars], IDs):-getCriticalTasks(ES, LS, Tars, IDs).

getES([], []).
getES([DataI|StartDates], [ESi|ES]):-
    get_min(DataI, ESi),
    getES(StartDates, ES).

getLS([], []).
getLS([DataI|StartDates], [LSi|LS]):-
    get_max(DataI, LSi),
    getLS(StartDates, LS).

prec_constrs([], _, _).
prec_constrs([I|Tars], StartDates, Concl):-
    element(I, StartDates, DataI),
    tarefa(I,Y,Di, _),
    prec_constrs_(Y, StartDates, DataI, Di),
    DataI + Di #=< Concl,
    prec_constrs(Tars, StartDates, Concl).

prec_constrs_([],_,_,_).
prec_constrs_([J|RTSegs],StartDates,DataI,Di) :- 
     element(J,StartDates,DataJ),
     DataI + Di #=< DataJ,
     prec_constrs_(RTSegs,StartDates,DataI,Di).

getMaxDurationAndMaxWorkers([],[],0,0).
getMaxDurationAndMaxWorkers([Di|Durations], [Wi|Workers], MaxDuration, MaxWorkers):-
    getMaxDurationAndMaxWorkers(Durations, Workers, SumD, SumW),
    MaxDuration is SumD + Di,
    MaxWorkers is SumW + Wi.

getDurationsAndWorkers([], _, []).
getDurationsAndWorkers([ID|IDs], [Di|Durations], [Wi|Workers]):-
    tarefa(ID, _, Di, Wi),
    getDurationsAndWorkers(IDs, Durations, Workers).

call_nth(Goal_0, Nth) :-
    shelf_create(counter(0), CounterRef),
    call(Goal_0),
    shelf_inc(CounterRef, 1),
    shelf_get(CounterRef, 1, Nth).
 
 findfirstn(N, Template, Goal_0, Instances) :-
    findall(Template, call_firstn(Goal_0, N), Instances).
 
 call_firstn(Goal_0, N) :-
    N + N mod 1 >= 0, % ensures that N >=0 and N is an integer
    call_nth(Goal_0, Nth),
    ( Nth == N -> ! ; true ).