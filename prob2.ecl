:- lib(ic).
:- lib(ic_global).
:- lib(branch_and_bound).

go(Dados) :- compile(Dados), obter_dados(Tarefas, Intervalos, Trabalhadores), 
length(Tarefas, N),
length(HorasDeInicio, N),
length(DatasDeInicio, N),
prazo(d(Prazo,_,_)),  %% assumindo que prazo é um dia e ignorando completamente que existem meses
datadeinicio_constrs(Tarefas, DatasDeInicio, Prazo),
horadeinicio_constrs(Tarefas, DatasDeInicio ,HorasDeInicio).


%%Estou ignorando intervalos e assumindo que só tem 1 mes
%% basicamente olhando só para os dias

obter_dados(Tarefas, Intervalos, Trabalhadores) :- 
	findall(ID,tarefa(ID,_,_,_,_),Tarefas), 
    findall(J,intervalo(J,_,_,_),Intervalos),
    findall(T,trabalhador(T,_),Trabalhadores).


datadeinicio_constrs([],_,_).
datadeinicio_constrs([ID|Tars], DatasDeInicio, Prazo) :-
	element(ID, DatasDeInicio, DataI),
	DataI :: [1..31],
	tarefa(ID,Prec,_,_,_),
	datadeinicio_constrs_(Prec,DatasDeInicio,DataI),
	DataI #=< Prazo,
	datadeinicio_constrs(Tars, DatasDeInicio, Prazo).

datadeinicio_constrs_([],_,_).
datadeinicio_constrs_([P|Precs],DatasDeInicio,DataI) :-
	element(P, DatasDeInicio, DataJ),
	DataI #=< DataJ,
	datadeinicio_constrs_(Precs,DatasDeInicio,DataI).


horadeinicio_constrs([],_,_).
horadeinicio_constrs([ID|Tars], HorasDeInicio, DatasDeInicio) :-
	element(ID, HorasDeInicio, Hi),
	element(ID, DatasDeInicio, DataI),
	tarefa(ID, Prec, Duri,_,_),
	horadeinicio_constrs_(Prec,HorasDeInicio, DataI ,Hi, Duri),
	Hi :: [8..12, 13..17],
	Hi #=< 17,
	horadeinicio_constrs(Tars, HorasDeInicio, DatasDeInicio).


horadeinicio_constrs_([],_,_,_).
horadeinicio_constrs_([P|Precs],HorasDeInicio,DataI,Hi,Duri) :- 
     element(P,HorasDeInicio,Hj),
     element(P,DatasDeInicio,DataJ),
     DataI #=< DataJ,
     Hi + Duri #=< (DataJ-DataI) * 24 + Hj, %%ignorando intervalos
     Hi + Duri #=< Hj,
     prec_constrs_(Precs,HorasDeInicio,DataI,Hi,Duri).








