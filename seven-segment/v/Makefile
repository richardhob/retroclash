
SRC:=SevenSegment.v
SRC_C:=tb.cpp

OBJ:=obj_dir/VSevenSegment

.PHONY: all
all: $(OBJ)
	$(OBJ)

$(OBJ): $(SRC_C) $(SRC)
	$(VERILATOR_ROOT)/bin/verilator --build -Wall --cc --exe --trace $^
