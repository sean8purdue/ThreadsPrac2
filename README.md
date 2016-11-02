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


