This is a university project. To run the compiler please use the next commands:

flex compiler.l
bison –v –d bison.y
gcc lex.yy.c bison.tab.c -o a -lfl
/a.out test1.f

There is a make file as well, so you can run it by typing make on the command line.

This project still has some conflicts.