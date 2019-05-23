:- lib(ic).
:- lib(ic_global).
:- lib(branch_and_bound).
:- lib(clpfd).


%%no calendario, datas devem ser convertidas para inteiros, em que a primeira é 1,
%% e as seguintes sao quantos dias passaram entre elas e a primeira

go(Dados) :- compile(Dados), obter_dados(Tarefas, IntervalosTo,IntervalosFrom, Trabalhadores, Especializacoes, RequisitosPorTarefa), 
length(Tarefas, N),
length(HorasDeInicio, N),
length(DatasDeInicio, N),
prazo(d(DiaPrazo,MesPrazo,_)),  %% assumindo que prazo é um dia e ignorando completamente que existem meses
calendario(Datas), 
calendario_to_list(Datas, DatasPossiveis,DiaPrazo, MesPrazo,Prazo), %% tambem determina o prazo

write("Datas Possíveis: "),
writeln(DatasPossiveis),
write("Dia do prazo: "),
writeln(Prazo),

DatasDeInicio :: DatasPossiveis, 

datadeinicio_constrs(Tarefas, DatasDeInicio, Prazo),
horadeinicio_constrs(Tarefas, DatasDeInicio ,HorasDeInicio),
intervalo_constrs(IntervalosTo, IntervalosFrom, HorasDeInicio, DatasDeInicio),
trabalhadores_constrs(RequisitosPorTarefa, ListaDeVariaveis),
trabalhadores_prec_constrs(Tarefas,DatasDeInicio, HorasDeInicio, ListaDeVariaveis),
writeln(ListaDeVariaveis),
term_variables([ListaDeVariaveis, HorasDeInicio, DatasDeInicio], Vars),
labeling(Vars),

write("Horas de Início: "),
writeln(HorasDeInicio),
write("Datas de Início: "),
writeln(DatasDeInicio).




element_list(1, [X|T], X).
element_list(N, [_|T], X):-
	element_list(N_, T, X), N is N_ + 1.

trabalhadores_prec_constrs([],_,_,_).
trabalhadores_prec_constrs([ID|Tarefa], DatasDeInicio, HorasDeInicio, ListaDeVariaveis):-
	element(ID, HorasDeInicio, Hi),
	element(ID, DatasDeInicio, DataI),
	element_list(ID, ListaDeVariaveis, TrabI),
	tarefa(ID,_,DurI,_,_),
	trabalhadores_prec_constrs_(Tarefa, Hi, DataI, DurI, TrabI,HorasDeInicio, DatasDeInicio, ListaDeVariaveis).

trabalhadores_prec_constrs_([],_,_,_,_,_).
trabalhadores_prec_constrs_([IDJ|Tarefa], Hi, DataI, DurI,TrabI ,HorasDeInicio, DatasDeInicio, ListaDeVariaveis) :-

	element(IDJ, HorasDeInicio, Hj),
	element(IDJ, DatasDeInicio, DataJ),
	element_list(IDJ, ListaDeVariaveis, TrabJ),
	tarefa(IDJ, _, DurJ, _,_),
	append(TrabI, TrabJ, TrabIJ),
	nvalue(CardinalConcatenacao,TrabIJ),
	length(TrabIJ, TamanhoLista),
	((DataI*24 + Hi #< DataJ*24 + Hj +DurJ) #/\ (DataJ*24 + Hj #< DataI*24 + Hi + DurI)) #==> (TamanhoLista #= CardinalConcatenacao) ,
	trabalhadores_prec_constrs_(Tarefa, Hi, DataI, DurI, TrabI ,HorasDeInicio, DatasDeInicio, ListaDeVariaveis).



trabalhadores_constrs([],[]).
trabalhadores_constrs([RequisitosTarefa|Resto], [SubFlat|ListaDeVariaveis]) :-
	length(RequisitosTarefa, Nrequisitos),length(Sub,Nrequisitos),
	construct_list(RequisitosTarefa,Sub), flatten(Sub, SubFlat),ic_global:alldifferent(SubFlat),trabalhadores_constrs(Resto, ListaDeVariaveis).

construct_list([],[]).
construct_list([r(E,N)|RequisitosTarefa],[Sub1|Sub]) :-
	length(Sub1, N), fill_list(E,Sub1),construct_list(RequisitosTarefa, Sub).

fill_list(_,[]).
fill_list(E,[X|Sub1]):-
	findall(IdTrab,(trabalhador(IdTrab, ListEspec),member(E,ListEspec)), ListIdsTrabs), 
	X :: ListIdsTrabs,
	fill_list(E,Sub1).

%RequisitosPorTarefa = [[r(T,N)],[]]


%%Estou assumindo que só tem 1 mes
%% basicamente olhando só para os dias
%% e assumindo que qualquer tarefa pode começar em qualquer dia do mes (ignorando o calendario)
calendario_to_list([d(_,_,6)|Datas], RestoLista, DiaPrazo, MesPrazo, Prazo) :-
	calendario_to_list(Datas,RestoLista,DiaPrazo,MesPrazo,Prazo).
calendario_to_list([d(_,_,7)|Datas], RestoLista, DiaPrazo, MesPrazo, Prazo) :-
	calendario_to_list(Datas,RestoLista,DiaPrazo,MesPrazo,Prazo).
calendario_to_list([d(Dia1,Mes1,_)|Datas], [1|RestoLista], DiaPrazo, MesPrazo, Prazo) :-
	Prazo is 31*(MesPrazo-Mes1) + (DiaPrazo-Dia1+1),
	calendario_to_list_(Dia1,Mes1,Datas,RestoLista).

calendario_to_list_(_,_,[],[]).
calendario_to_list_(Dia1, Mes1, [d(_,_,6)|Datas], RestoLista) :- 
	calendario_to_list_(Dia1, Mes1, Datas, RestoLista).
calendario_to_list_(Dia1, Mes1, [d(_,_,7)|Datas], RestoLista) :- 
	calendario_to_list_(Dia1, Mes1, Datas, RestoLista).
calendario_to_list_(Dia1, Mes1, [d(Data,Mes,_)|Datas], [Dia|RestoLista]) :- 
	Dia is (Data-Dia1+1) + 31*(Mes-Mes1),
	calendario_to_list_(Dia1, Mes1, Datas, RestoLista).

obter_dados(Tarefas, IntervalosTo,IntervalosFrom, Trabalhadores, Especializacoes, RequisitosPorTarefa) :- 
	findall(ID,tarefa(ID,_,_,_,_),Tarefas), 
    findall(J,intervalo(J,_,_,_),IntervalosTo),
    findall(K,intervalo(_,K,_,_),IntervalosFrom),
    findall(T,trabalhador(T,_),Trabalhadores),
    findall(E,trabalhador(_,E),Especializacoes),
    findall(R,tarefa(_,_,_,R,_),RequisitosPorTarefa) .

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



