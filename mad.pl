:- lib(ic).
% :- lib(ic_edge_finder).% for cumulative/4
:- lib(branch_and_bound).% for minimize/2

% tarefa(Idt,ListaIdts,Duracao,Ntrabs)

tarefa(1, [2], 5, 1).
tarefa(2, [3], 4, 1).
tarefa(3, [], 7, 1).
tarefa(4, [3, 5], 8, 1).
tarefa(5, [], 3, 1).
tarefa(6, [3, 7], 10, 1).
tarefa(7, [5], 2, 1).

% tarefa(1, [2], 5, 1).
% tarefa(2, [ ], 6, 1).
% tarefa(3,[4],2, 1).
% tarefa(4,[],3, 1).
% tarefa(5,[],11, 1).

go:-
    findall(X,tarefa(X,_,_,_),Tars),
    findall(Y,tarefa(_,_,Y,_),SumDi),
    length(Tars,N),
    length(ES,N),
    length(EF,N),
    length(LF,N),
    maxduracao(SumDi, MaxConcl),
    [Concl|ES] :: 0..MaxConcl,
    LF :: 0..MaxConcl,
    get_EF(ES,EF,Tars),
    
    prec_constrs(Tars, ES, LF, Concl),
    term_variables([ES, LF, Concl], Vars),
    minimize(labeling(Vars), Concl),
     
    write('Earliest Start: '),
    writeln(ES),
    write('Earliest Finish: '),
    writeln(EF),
    write('Latest Finish: '),
    writeln(LF).

prec_constrs([], _, _,_).
prec_constrs([I|Tars], ES, LF, Concl):-
    element(I, ES, ESi),
    element(I, LF, LFi),
    tarefa(I,Y,Di,_),
    get_LF(Y, LF, LFi, Concl),
    prec_constrs_(Y, ES, ESi, Di),
    % lf_constrs(Y, ES, LFi),
    ESi + Di #=< Concl,
    prec_constrs(Tars, ES, LF, Concl).

get_LF([], _,LFi,LFi).
get_LF([J|RT], LF, LFi, Concl):-
    element(J, LF, LFj),
    tarefa(J, _, Dj, _),
    Tmp #= LFj - Dj,
    LFi #= min(Tmp, Concl),
    get_LF(RT, LF, LFi, Tmp).

get_EF(_,_,[]).
get_EF(ES,EF,[I|Tars]):-
    tarefa(I,_,Di,_),
    element(I, ES, ESi),
    element(I, EF, EFi),
    EFi #= ESi + Di,
    get_EF(ES,EF,Tars).

prec_constrs_([],_,_,_).
prec_constrs_([J|RTSegs],Datas,ESi,Di) :- 
     element(J,Datas,DataJ),
     ESi + Di #=< DataJ,
     prec_constrs_(RTSegs,Datas,ESi,Di).

maxduracao([],0).
maxduracao([Di|RTarefas],Somaf):-
     maxduracao(RTarefas,Soma), Somaf is Soma+Di.