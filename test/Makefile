SRC_DIR     = .
SCHEMA_FILE = $(SRC_DIR)/schema.xml
GEN_DIR     = $(SRC_DIR)/gen
OUT_FILE    = $(SRC_DIR)/store_raise_event
CONSOLE_FILE= $(SRC_DIR)/event_listener

CC           = gcc
CC_INCLUDES  = -I$(SRC_DIR) -I$(GEN_DIR)
CC_FLAGS     = -g -O3
ifdef OLD_QMF
LD_FLAGS     = -lqmfagent
else
LD_FLAGS     = -lqmf
endif
CONSOLE_FLAGS= -lqmfconsole
MGEN         = /usr/bin/qmf-gen

vpath %.cpp $(SRC_DIR):$(GEN_DIR)
vpath %.d   $(OBJ_DIR)
vpath %.o   $(OBJ_DIR)

cpps = $(wildcard $(SRC_DIR)/store_raise_event.cpp)
console_cpps = $(wildcard $(SRC_DIR)/listener.cpp)
cpps += $(wildcard $(GEN_DIR)/qmf/mrg/grid/config/*.cpp)
console_cpps += $(wildcard $(GEN_DIR)/qmf/mrg/grid/config/*.cpp)
dep = $(addsuffix .d, $(basename $(cpps)))
console_dep = $(addsuffix .d, $(basename $(console_cpps)))
objects = $(addsuffix .o, $(basename $(cpps)))
console_objects = $(addsuffix .o, $(basename $(console_cpps)))

.PHONY: all clean gen

ifeq ($(MAKELEVEL), 0)

all: gen
	@$(MAKE)

gen:
	$(MGEN) -o $(GEN_DIR)/qmf $(SCHEMA_FILE)

clean:
	rm -rf $(GEN_DIR) $(OUT_FILE) $(CONSOLE_FILE) *.d *.o

else ifeq ($(MAKELEVEL), 1)

all: $(deps)
	@$(MAKE)

%.d : %.cpp
	$(CC) -M $(CC_FLAGS) $(CC_INCLUDES) $< > $@

else ifeq ($(MAKELEVEL), 2)

all: $(OUT_FILE) $(CONSOLE_FILE)

$(OUT_FILE) : $(objects)
	$(CC) -o $(OUT_FILE) $(CC_FLAGS) $(LD_FLAGS) $(objects)

$(CONSOLE_FILE) : $(console_objects)
	$(CC) -o $(CONSOLE_FILE) $(CC_FLAGS) $(CONSOLE_FLAGS) $(console_objects)

include $(deps)

%.o : %.cpp
	$(CC) -c $(CC_FLAGS) $(CC_INCLUDES) -o $@ $<

endif


