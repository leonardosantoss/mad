# mad

# Problema 1:

* Solução em eclipse: prob1.ecl

No ambiente do eclipse-clp:

Para compilar basta:

```
  compile("prob1.ecl").
```

Para rodar basta (Dados representa o ficheiro em que dados estão guardados):

```
  go(Dados).
```
* Solução em c++: prob1.cpp

Para compilar basta:
```
  g++ prob1.cpp
```

Para correr programa basta:
 ```
 ./a.out
 ```
 No caso de dados serem demasiados grandes, rodar programa com a seguinte opção para macOS:
  ```
 ./a.out ulimit -s 65532
 ```

 
 Observações Importantes:
 
 Dados devem se encontrar no ficheiro "data.txt", e serem da forma definida para os dados em prolog.
 Cada linha deve conter:
 ```
    tarefa(Idt,ListaIdts,Duracao,Ntrabs)
  ```
  E não devem haver linhas em branco nem comentários. Programa está definido para tratar no máximo 1500 tarefas.
  Tarefas devem ter id's inteiros de 1 até a maior tarefa e todas devem estar em ordem crescente no arquivo de dados.
  
