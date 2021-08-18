all: bin/postfix
	@echo Done!

bin/postfix: obj/main.o obj/postfix.o
	@echo Linking...
	@gcc -m32 obj/*.o -o bin/postfix 

obj/main.o: src/main.c 
	@echo Assembling_main...
	@gcc -m32 -c src/main.c -o obj/main.o 

obj/postfix.o: src/postfix.s 
	@echo Assembling_postfix...
	@gcc -m32 -c src/postfix.s -o obj/postfix.o 

clean:
	@echo Cleaning...
	@rm -rf obj/*.o bin/*
	@echo Done!
