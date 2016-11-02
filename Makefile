
all: thr1 thr2 count bcount mcount count_spin deadlock

thr1: thr1.cc
	g++ -o thr1 thr1.cc -lpthread

thr2: thr2.cc
	g++ -o thr2 thr2.cc -lpthread

count: count.cc
	g++  -o count count.cc -lpthread

bcount: count_bug.cc
	g++ -g -o bcount count_bug.cc -lpthread

mcount: count_masterLock.cc
	g++ -g -o mcount count_masterLock.cc -lpthread

count_spin: count_spin.cc
	g++  -o count_spin count_spin.cc -lpthread

deadlock: deadlock.cc
	g++  -o deadlock deadlock.cc -lpthread

clean:
	rm -f *.o thr1 thr2 count count_spin deadlock bcount
