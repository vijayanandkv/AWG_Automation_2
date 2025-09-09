all: CFLAGS += $(shell pkg-config --cflags libadq) -DLINUX
all: LIBS += $(shell pkg-config --libs libadq)
all: adqapiexample
debug: CFLAGS += $(shell pkg-config --cflags libadq) -DLINUX
debug: LIBS += $(shell pkg-config --libs libadq)

local: CFLAGS += -DLINUX
local: LIBS += -ladq -ludev -lpthread -lstdc++
local:example*.c
	$(CXX) $(CFLAGS) -I../../Release -o adqapiexample example*.c -L../../source/.libs $(LIBS)

debug:example*.c
	$(CXX) $(CFLAGS) -g -o adqapiexample example*.c $(LIBS)

adqapiexample:example*.c
	$(CXX) $(CFLAGS) -o adqapiexample example*.c $(LIBS)

clean:
	rm -f adqapiexample
