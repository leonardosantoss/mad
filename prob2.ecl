:- lib(ic).
:- lib(ic_global).
:- lib(branch_and_bound).
:- lib(clpfd).


%%no calendario, datas devem ser convertidas para inteiros, em que a primeira é 1,
%% e as seguintes sao quantos dias passaram entre elas e a primeira

go(Dados) :- compile(Dados), obter_dados(Tarefas, IntervalosTo,IntervalosFrom, Trabalhadores), 
length(Tarefas, N),
length(HorasDeInicio, N),
length(DatasDeInicio, N),
DatasDeInicio :: 1..31, %% trocar para o intervalo do calendario, no futuro
prazo(d(Prazo,_,_)),  %% assumindo que prazo é um dia e ignorando completamente que existem meses
datadeinicio_constrs(Tarefas, DatasDeInicio, Prazo),
horadeinicio_constrs(Tarefas, DatasDeInicio ,HorasDeInicio),
intervalo_constrs(IntervalosTo, IntervalosFrom, HorasDeInicio, DatasDeInicio),
term_variables([HorasDeInicio, DatasDeInicio], Vars),
labeling(Vars),
writeln(HorasDeInicio),
writeln(DatasDeInicio).


%%Estou assumindo que só tem 1 mes
%% basicamente olhando só para os dias
%% e assumindo que qualquer tarefa pode começar em qualquer dia do mes (ignorando o calendario)

obter_dados(Tarefas, IntervalosTo,IntervalosFrom, Trabalhadores) :- 
	findall(ID,tarefa(ID,_,_,_,_),Tarefas), 
    findall(J,intervalo(J,_,_,_),IntervalosTo),
    findall(K,intervalo(_,K,_,_),IntervalosFrom),
    findall(T,trabalhador(T,_),Trabalhadores).

intervalo_constrs([], [], _, _).
intervalo_constrs([To|IntervalosTo], [From|IntervalosFrom], HorasDeInicio, DatasDeInicio) :-
	element(From, HorasDeInicio,Hi),
	element(From, DatasDeInicio, DataI),
	element(To, DatasDeInicio, DataJ),
	element(To, HorasDeInicio, Hj),
	tarefa(From, _,DurI,_,_),
	intervalo(To,From,MinInterval, MaxInterval),
	Hi + DurI + MinInterval #=< (DataJ-DataI) * 24 + Hj,
	Hi + DurI + MaxInterval #>= (DataJ-DataI) * 24 + Hj,
	intervalo_constrs(IntervalosTo, IntervalosFrom, HorasDeInicio, DatasDeInicio).



datadeinicio_constrs([],_,_).
datadeinicio_constrs([ID|Tars], DatasDeInicio, Prazo) :-
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
horadeinicio_constrs([ID|Tars], DatasDeInicio, HorasDeInicio) :-
	element(ID, HorasDeInicio, Hi),
	element(ID, DatasDeInicio, DataI),
	Hi :: [8..12, 13..17],
	tarefa(ID, Prec, DurI,_,_),
	horadeinicio_constrs_(Prec,DatasDeInicio,HorasDeInicio ,DataI ,Hi, DurI),
	((Hi#=<12 #/\ Hi+DurI#=<12) #\/ (Hi#>=13 #/\ Hi+DurI#=<17)),
	horadeinicio_constrs(Tars, DatasDeInicio, HorasDeInicio).


horadeinicio_constrs_([],_,_,_,_,_).
horadeinicio_constrs_([P|Precs],DatasDeInicio,HorasDeInicio,DataI,Hi,DurI) :- 
     element(P,HorasDeInicio,Hj),
     element(P,DatasDeInicio,DataJ),
     DataI #=< DataJ,
     Hi + DurI #=< (DataJ-DataI) * 24 + Hj, %%ignorando intervalos
     horadeinicio_constrs_(Precs,DatasDeInicio,HorasDeInicio,DataI,Hi,DurI).



