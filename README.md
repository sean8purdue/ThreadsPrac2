# CS252 Project4


## Part1

### 1.1 Output of Step3 (thr1.cc)

Code

~~~cpp
	pthread_create( &t1, &attr, (void * (*)(void *)) printC, (void *) "A" );
	pthread_create( &t2, &attr, (void * (*)(void *)) printC, (void *) "B" );
	
	pthread_create( &t1, &attr, (void * (*)(void *)) printC, (void *) "D" );
	pthread_create( &t1, &attr, (void * (*)(void *)) printC, (void *) "E" );

	printC("C");
~~~

Output: The patern is changed from ADEBC to ACBED in this example. It's proved that the execution of thread is randomly.

~~~
ADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBCADEBC

ACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBEDACBED
~~~

### 1.2 Output of step5

Original Code

~~~cpp
void printC( const char * s )
{
	while (1) {
		printf("%s", s );
	}
}


int main( int argc, char ** argv )
{
	pthread_t t1, t2;
	pthread_attr_t attr;

	pthread_attr_init( &attr );
	pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);

	printC("C");

	pthread_create( &t1, &attr, (void * (*)(void *)) printC, (void *) "A" );
	pthread_create( &t2, &attr, (void * (*)(void *)) printC, (void *) "B" );

}
~~~

Since the printC function is a infinite loop, in the main thread we get stuck in `printC("C")`, it can not create new threads which print "A", "B".

Correct Code shoud be 

~~~cpp

	pthread_create( &t1, &attr, (void * (*)(void *)) printC, (void *) "A" );
	pthread_create( &t2, &attr, (void * (*)(void *)) printC, (void *) "B" );
	printC("C");

~~~

## Part2

### 2.1 Examine the `count.cc` file 

Run count several times, the count is incorrect. Since **count** is a global variable, each thread can access and modify it at the same time

The context switch from one thread to another may change the sequence of events, so the counter may lose some of the counts.

~~~
➜  lab4-src git:(part2_MutualExclusion) ./count
Start Test. Final count should be 20000000

****** Error. Final count is 9898598
****** It should be 20000000
➜  lab4-src git:(part2_MutualExclusion) ./count
Start Test. Final count should be 20000000

****** Error. Final count is 10151130
****** It should be 20000000
➜  lab4-src git:(part2_MutualExclusion) ./count
Start Test. Final count should be 20000000

****** Error. Final count is 10911438
****** It should be 20000000
➜  lab4-src git:(part2_MutualExclusion)
~~~

### 2.2 Fix above problem with MutexLock

* Try 1 Local mutex lock

If you add mutex lock in function `increment(int times)`, it will not work!!! 

~~~cpp
void increment(int ntimes )
{
	pthread_mutex_t mutex;
	for ( int i = 0; i < ntimes; i++ ) {
		int c;

	pthread_mutex_lock(&mutex);
		c = count;
		c = c + 1;

		count = c;
	pthread_mutex_unlock(&mutex);
	}
}
~~~

* Try 2 Global mutex lock

➜  Correct Version

~~~cpp
void increment(int ntimes )
{
		pthread_mutex_lock( &mutex );
	   for ( int i = 0; i < ntimes; i++ ) {
			int c;

			c = count;
			c = c + 1;

			count = c;
		}
		pthread_mutex_unlock( &mutex );
}
~~~

➜  GDB debug result (Correct MutexLock Version):

Thread 3 hit `&mutex` fist, it seems like T3 doesn't lock after execute ` pthread_mutex_lock( &mutex )`. Actually, T3 doesn't execute  ` pthread_mutex_lock( &mutex )`. At this time, OS switch to Thread 2, and T2 lock the MutexLock and then begin running in function `increment(int ntimes)`. 
 
~~~
Starting program: /Users/Sean/Desktop/lab4-src/bcount
Start Test. Final count should be 10
[New Thread 0x1597 of process 6719]
[New Thread 0x169f of process 6719]
[Switching to Thread 0x169f of process 6719]

Thread 3 hit Breakpoint 1, increment (ntimes=5) at count_bug.cc:12
12     			pthread_mutex_lock( &mutex );
(gdb) n
[Switching to Thread 0x1597 of process 6719]

Thread 2 hit Breakpoint 1, increment (ntimes=5) at count_bug.cc:12
12     			pthread_mutex_lock( &mutex );
(gdb) n
13     		for ( int i = 0; i < ntimes; i++ ) {
(gdb)
16     			c = count;
(gdb)
17     			c = c + 1;
(gdb)

Thread 2 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:19
19     			count = c;
(gdb)
~~~
Thread 2 run through `for loop`, until hit `pthread_mutex_unlock( &mutex );`. Unlock MutexLock, and end running in function `increment(int ntimes)`, then <mark>Thread2 End</mark>.

Then OS switch to Thread3, hit Breakpoint in `for loop`, then run through the loop, until hit `pthread_mutex_unlock( &mutex );`, unlock mutex lock, then run through function `increment(int ntimes)`, and <mark>Thread3 End</mark>.

~~~
Thread 2 hit Breakpoint 3, increment (ntimes=5) at count_bug.cc:21
21     			pthread_mutex_unlock( &mutex );
(gdb)
22     	}
(gdb)
0x00007fff8366d99d in _pthread_body () from /usr/lib/system/libsystem_pthread.dylib
(gdb)
Single stepping until exit from function _pthread_body,
which has no line number information.
[Switching to Thread 0x169f of process 6719]

Thread 3 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:19
19     			count = c;
(gdb) n
~~~

**Warning:**
In main thread, 

After `pthread_join( t1, NULL );`, thread t1 will end. 

After `pthread_join( t2, NULL );`, thread t2 will end.

Thread3 run through function `increment(int ntimes)`, **not** return from function `increment(int ntimes)` back to `main function`. Don't mess this!! 

**Thread is not function call, do not need to return!!**

~~~cpp
	// Wait until threads are done
	pthread_join( t1, NULL );
	pthread_join( t2, NULL );

~~~ 

~~~
Thread 3 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:19
19     			count = c;
(gdb)

Thread 3 hit Hardware watchpoint 4: count

Old value = 7
New value = 8
increment (ntimes=5) at count_bug.cc:13
13     		for ( int i = 0; i < ntimes; i++ ) {
(gdb)
16     			c = count;
(gdb) info threads
  Id   Target Id         Frame
  1    Thread 0x13bb of process 8030 0x00007fff9420410a in __semwait_signal ()
   from /usr/lib/system/libsystem_kernel.dylib
* 3    Thread 0x1ab7 of process 8030 increment (ntimes=5) at count_bug.cc:16
(gdb) n
~~~

* Try 3 Bugs Analysis

3.1 Bug 3.1

It's confused why this mutex lock doesn't work?

~~~cpp
void increment(int ntimes )
{
	   for ( int i = 0; i < ntimes; i++ ) {
			int c;
		   pthread_mutex_lock( &mutex );
			c = count;
			c = c + 1;

			count = c;
		   pthread_mutex_unlock( &mutex );
		}
}
~~~

~~~cpp
void increment(int ntimes )
{
	   for ( int i = 0; i < ntimes; i++ ) {
	   	    pthread_mutex_lock( &mutex );
			int c;
		
			c = count;
			c = c + 1;

			count = c;
			pthread_mutex_unlock( &mutex );
		}
		
}
~~~

<mark>**Bug Fix**:

If lock mutexLock in the loop, when thread t1 run the second time in loop, it will try to lock the same mutexLock again, which will make the thread itself to `wait` state.

<mark>Never put mutexLock in loop!!!

~~~
(gdb) r
Starting program: /Users/Sean/Desktop/new/bcount
Start Test. Final count should be 10
[New Thread 0x1313 of process 11214]
[New Thread 0x1403 of process 11214]

Thread 1 hit Breakpoint 2, main (argc=1, argv=0x7fff5fbffa70) at count_bug.cc:45
45     		pthread_join( t1, NULL );
(gdb) n
[Switching to Thread 0x1313 of process 11214]

Thread 2 hit Breakpoint 1, increment (ntimes=5) at count_bug.cc:16
16     			c = count;
(gdb) n
17     			c = c + 1;
(gdb)
19     			count = c;
(gdb)
12     		for ( int i = 0; i < ntimes; i++ ) {
(gdb)
➜  13     			pthread_mutex_lock( &mutex ); 
(gdb)
~~~

The arrow line display that the running thread try to lock the same mutexLock again,

3.2 Bug 3.2

These mutex locks also don't work?

~~~cpp
void increment(int ntimes )
{
		pthread_mutex_lock( &mutex );
	   for ( int i = 0; i < ntimes; i++ ) {
			int c;

			c = count;
			c = c + 1;

			count = c;
		pthread_mutex_unlock( &mutex );
		}
}
~~~

~~~cpp
void increment(int ntimes )
{
	   for ( int i = 0; i < ntimes; i++ ) {
			int c;
		pthread_mutex_lock( &mutex );

			c = count;
			c = c + 1;

			count = c;
		}
		pthread_mutex_unlock( &mutex );
}
~~~

## Part4

### 1. Problem Analysis

Deadlock in the following mark.

When thread 1 (T1) execute statement 1 (S1). MutexLock (M1) lock. If this time there is a context switch, thread 2 (T2) begin to execute. 

T2 run S7, and lock M2, when T2 run S8, since M1 has been locked by T1, so T2 transfer to wait state (block), and OS context swich back to T1.

Then T1 execute S2, since M2 has been locked by T2, so T1 transfer to wait state (block), and try to switch back to T2. But T2 is already in wait state (blocked). T1, T2 wait for each other, will never continue, blocked at S2, S8 respectively.

As a result, T1, T2 are both blocked (in wait state). When Main thread run to S13, main thread will wait until T1 end, but T1 will never end, since it is in deadlock.

~~~c
void transfer1to2(int amount)
{
1        pthread_mutex_lock(&m1);
2        pthread_mutex_lock(&m2);
3        balance1 -= amount;
4        balance2 += amount;
5        pthread_mutex_unlock(&m1);
6        pthread_mutex_unlock(&m2);
}

void transfer2to1( int amount )
{
➜7       pthread_mutex_lock(&m2);
 8       pthread_mutex_lock(&m1);
 9       balance2 -= amount;
 10       balance1 += amount;
 11       pthread_mutex_unlock(&m2);
 12       pthread_mutex_unlock(&m1);
}
~~~

~~~c
		// In main()
     // Wait until threads are done
13     pthread_join( t1, NULL );
14     pthread_join( t2, NULL );

~~~

### 2. Try different unlock order

Unlock Order doesn't matter, doesn't make any difference to deadlock.

~~~c
void transfer1to2(int amount)
{
        pthread_mutex_lock(&m1);
        pthread_mutex_lock(&m2);
        balance1 -= amount;
        balance2 += amount;
        pthread_mutex_unlock(&m1);
        pthread_mutex_unlock(&m2);
}

void transfer2to1( int amount )
{
➜       pthread_mutex_lock(&m1);
        pthread_mutex_lock(&m2);
        balance2 -= amount;
        balance1 += amount;
        pthread_mutex_unlock(&m1);
➜       pthread_mutex_unlock(&m2);
}
~~~


