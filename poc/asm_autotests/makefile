C = gcc
FS = asm
OBJ_D = obj
BIN_D = bin
SRC_D = src
NAME_S = call_from_s
NAME_C = call_from_c
FUNC_NAME = func
RUNNER = test
TEST_DIR =
DATA_DIR =			#TODO: export this as an environment variable and use as a path in test functions.
FUNC_PATH =

all: $(TEST_DIR)/$(BIN_D)/$(RUNNER)

$(TEST_DIR)/$(BIN_D): #create directory if it doesn't exist
	mkdir -p $@
$(TEST_DIR)/$(OBJ_D): #create directory if it doesn't exist
	mkdir -p $@

$(FUNC_PATH)/$(OBJ_D)/$(FUNC_NAME).o: $(FUNC_PATH)/$(SRC_D)/$(FUNC_NAME).asm #recursively invoke make to build object file in function directory
	make -C $(FUNC_PATH) all

$(TEST_DIR)/$(OBJ_D)/$(FUNC_NAME).o: $(FUNC_PATH)/$(OBJ_D)/$(FUNC_NAME).o $(TEST_DIR)/$(OBJ_D) #create symlink to function object directory
	ln -sf $< $(TEST_DIR)/$(OBJ_D)/$(<F)

$(TEST_DIR)/$(BIN_D)/$(RUNNER): $(TEST_DIR)/$(OBJ_D)/$(FUNC_NAME).o $(TEST_DIR)/$(SRC_D)/$(RUNNER).c $(TEST_DIR)/$(BIN_D) #compile test program
	$(C) $(TEST_DIR)/$(SRC_D)/$(RUNNER).c $< -o $@
			
clean:
	rm -rf $(TEST_DIR)/$(BIN_D) $(TEST_DIR)/$(OBJ_D)

.PHONY : clean
