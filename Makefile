all: exe

exe: Node.o Llist.o Hashtable.o lex.yy.o y.tab.o parser.cc *.h
	g++ -g Node.o Llist.o Hashtable.o lex.yy.o y.tab.o parser.cc -lfl -o exe

Node.o: Node.cpp Node.h
	g++ -g -c Node.cpp

Llist.o: Llist.cpp Llist.h
	g++ -g -c Llist.cpp

Hashtable.o: Hashtable.cpp Hashtable.h
	g++ -g -c Hashtable.cpp

lex.yy.o: lex.yy.c y.tab.c
	g++ -g -c lex.yy.c

lex.yy.c: lex_analyzer.l 
	lex lex_analyzer.l

y.tab.o: y.tab.c *.h
	g++ -g -c y.tab.c

y.tab.c: parser.y
	yacc -d parser.y

clean:
	rm exe *.o y.tab.h y.tab.c lex.yy.c *.out