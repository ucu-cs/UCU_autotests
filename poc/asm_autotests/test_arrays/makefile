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

$(BIN_D)/$(NAME_C): $(OBJ_D)/$func.o
	$(C) $(SRC_D)/main.c $(OBJ_D)/func.o -o $(BIN_D)/$(NAME_S) -np-pie

$(BIN_D)/$(NAME_S): $(OBJ_D)/main.o $(OBJ_D)/func.o
	$(C) $(OBJ_D)/main.o $(OBJ_D)/func.o -o $(BIN_D)/$(NAME_S) -no-pie

$(OBJ_D)/main.o: $(SRC_D)/main.s
	$(FS) $(SRC_D)/main.s $(OBJ_D)/main.o

$(OBJ_D)/func.o: $(SRC_D)/func.s 
	$(FS) $(SRC_D)/func.s $(OBJ_D)/func.o


.PHONY : clean
clean:
	rm -rf bin/ obj/
