CXX   = g++-8
EXE = iplC
CXXDEBUG = -g 
CXXSTD = -std=c++11


.PHONY: all
all: parser lexer 	
	$(CXX) $(CXXDEBUG) $(CXXSTD) -o iplC driver.cpp parser.o scanner.o symbtab.cpp  

.PHONY: parser
parser: parser.yy scanner.hh
	bison -d -v $<
	$(CXX) $(CXXDEBUG) $(CXXSTD) -c parser.tab.cc -o parser.o 

.PHONY: lexer
lexer: scanner.l scanner.hh parser.tab.hh parser.tab.cc	
	flex++ --outfile=scanner.yy.cc  $<
	$(CXX)  $(CXXDEBUG) $(CXXSTD) -c scanner.yy.cc -o scanner.o

clean:
	rm -f *.s *.cc *.o *.out parser.output parser.tab.hh iplC outs/* stack.hh
