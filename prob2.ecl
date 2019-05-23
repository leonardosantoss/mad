:- lib(ic).
:- lib(ic_global).
:- lib(branch_and_bound).
:- lib(clpfd).



go(Dados) :- compile(Dados), obter_dados(Tarefas, IntervalosTo,IntervalosFrom, Trabalhadores, Especializacoes, RequisitosPorTarefa), 
length(Tarefas, N),
length(HorasDeInicio, N),
length(DatasDeInicio, N),
prazo(d(DiaPrazo,MesPrazo,_)),
calendario(Datas), 
calendario_to_list(Datas, DatasPossiveis,DiaPrazo, MesPrazo,Prazo), %% tambem determina o prazo

write("Datas Possíveis: "),
writeln(DatasPossiveis),
write("Dia do prazo: "),
writeln(Prazo),

DatasDeInicio :: DatasPossiveis, 
ic:max(Trabalhadores, MaxIndexTrab), 
Cost #>= MaxIndexTrab,

datadeinicio_constrs(Tarefas, DatasDeInicio, Prazo, Concl),
horadeinicio_constrs(Tarefas, DatasDeInicio ,HorasDeInicio),
intervalo_constrs(IntervalosTo, IntervalosFrom, HorasDeInicio, DatasDeInicio),
trabalhadores_constrs(RequisitosPorTarefa, ListaDeVariaveis, MaxIndexTrab,Cost),
trabalhadores_prec_constrs(Tarefas,DatasDeInicio, HorasDeInicio, ListaDeVariaveis),
write("Lista de variaveis: "),
writeln(ListaDeVariaveis),
term_variables([Cost,Concl,HorasDeInicio, DatasDeInicio,ListaDeVariaveis], Vars),

bb_min(labeling(Vars),Cost, _),

write("Trabalhadores por atividade: "),
writeln(ListaDeVariaveis),
write("Horas de Início: "),
writeln(HorasDeInicio),
write("Datas de Início: "),
writeln(DatasDeInicio),
write("Custo: "),
writeln(Cost).


obter_dados(TarefasSort, IntervalosTo,IntervalosFrom, TrabalhadoresSort, Especializacoes, RequisitosPorTarefa) :- 
	findall(ID,tarefa(ID,_,_,_,_),Tarefas),
	sort(Tarefas, TarefasSort),
    findall(J,intervalo(J,_,_,_),IntervalosTo),
    findall(K,intervalo(_,K,_,_),IntervalosFrom),
    findall(T,trabalhador(T,_),Trabalhadores),
    sort(Trabalhadores,TrabalhadoresSort),
    findall(E,(member(X,TrabalhadoresSort),trabalhador(X,E)),Especializacoes),
    findall(R,(member(X,TarefasSort),tarefa(X,_,_,R,_)), RequisitosPorTarefa).

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

trabalhadores_prec_constrs_([],_,_,_,_,_,_,_).
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



trabalhadores_constrs([],[],_,_).
trabalhadores_constrs([RequisitosTarefa|Resto], [SubFlat|ListaDeVariaveis], MaxIndexTrab,Cost) :-
	length(RequisitosTarefa, Nrequisitos),length(Sub,Nrequisitos),
	construct_list(RequisitosTarefa,Sub, MaxIndexTrab,Cost), 
	flatten(Sub, SubFlat),
	ic_global:alldifferent(SubFlat),
	trabalhadores_constrs(Resto, ListaDeVariaveis,MaxIndexTrab,Cost).

construct_list([],[],_,_).
construct_list([r(E,N)|RequisitosTarefa],[Sub1|Sub], MaxIndexTrab,Cost) :-
	length(Sub1, N), 
	fill_list(E,Sub1,MaxIndexTrab,Cost),
	construct_list(RequisitosTarefa, Sub,MaxIndexTrab,Cost).

fill_list(_,[],_,_).
fill_list(E,[X|Sub1],MaxIndexTrab,Cost):-
	writeln("k"),
	findall(IdTrab,(trabalhador(IdTrab, ListEspec),member(E,ListEspec)), ListIdsTrabs), 
	MaxPlusOne is MaxIndexTrab + 1,
	append(ListIdsTrabs, [MaxPlusOne..inf], Y),
	X :: Y,    %%%%%%%%%%%
	domain_lessthancost(X,Cost),
	fill_list(E,Sub1,MaxIndexTrab,Cost).

domain_lessthancost(_,_).
domain_lessthancost(X,Cost) :-
	X #=< Cost.

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



datadeinicio_constrs([],_,_,_).
datadeinicio_constrs([ID|Tars], DatasDeInicio, Prazo, Concl) :-
	DataI :: [1..31],
	tarefa(ID,Prec,_,_,_),
	datadeinicio_constrs_(Prec,DatasDeInicio,DataI),
	DataI #=< Concl,
	Concl #=< Prazo,
	datadeinicio_constrs(Tars, DatasDeInicio, Prazo,Concl).

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
     Hi + DurI #=< (DataJ-DataI) * 24 + Hj,
     horadeinicio_constrs_(Precs,DatasDeInicio,HorasDeInicio,DataI,Hi,DurI).



