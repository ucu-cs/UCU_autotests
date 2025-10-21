C = gcc
FS = asm
OBJ_D = obj
BIN_D = bin
SRC_D = src
NAME_S = call_from_s
NAME_C = call_from_c

all: mdr $(BIN_D)/$(NAME_S) $(BIN_D)/$(NAME_C)

mdr:
	test -d bin || mkdir $(BIN_D)
	test -d obj || mkdir $(OBJ_D)

.PHONY : clean
	clean:
		rm -rf bin/ obj/
