EXENAME := xbflash

CXX_EXT := cpp

CXX := g++

CXXFLAGS := -Wall -std=c++11 -pthread
RT_SRC_ROOT := ../../../..

# External Dependencies
#EXT_DEP_OBJ := scan
#EXT_DEP_DIR := $(RT_SRC_ROOT)/driver/xclng/xrt/user_gem

#CXXFLAGS += -I$(RT_SRC_ROOT)/driver/include/ 

#ifeq ($(debug),1)
	CXXFLAGS += -g -D_DEBUG 
#else
#	CXXFLAGS += -O2 -DNDEBUG -DVALIDATE
#endif

SRCS := $(wildcard *.$(CXX_EXT))
OBJS := $(patsubst %.$(CXX_EXT), %.o, $(SRCS))
#OBJS += $(EXT_DEP_DIR)/$(EXT_DEP_OBJ).o

-include $(OBJS:.o=.d)

LDFLAGS := -static-libstdc++ -pthread

all : $(EXENAME)

%.o: %.$(CXX_EXT)
	$(CXX) $(CXXFLAGS) -c $< -o $@
	$(CXX) $(CXXFLAGS) -c -MM $< -o $(patsubst %.o, %.d, $@)

$(EXENAME): $(OBJS)
	$(CXX) -o $@ $(OBJS) $(LDFLAGS) -lrt

clean:
	rm -rf *.o *.d $(EXENAME) 

.PHONY: all

.DEFAULT_GOAL := all
