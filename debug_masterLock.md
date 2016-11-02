# debug_masterLock

1. First version mutex lock in main thread

Code:

~~~cpp
int main( int argc, char ** argv )
{
	int n = 100000000;
	pthread_t t1, t2;
        pthread_attr_t attr;

	pthread_mutexattr_init( &mattr );
	pthread_mutex_init( &mutex, &mattr);

	pthread_mutex_lock( &mutex );

        pthread_attr_init( &attr );
        pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);

	printf("Start Test. Final count should be %d\n", 2 * n );

	// Create threads
	pthread_create( &t1, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);

	pthread_create( &t2, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);

	pthread_mutex_unlock( &mutex );

	// Wait until threads are done
	pthread_join( t1, NULL );
	pthread_join( t2, NULL );

	if ( count != 2 * n ) {
		printf("\n****** Error. Final count is %d\n", count );
		printf("****** It should be %d\n", 2 * n );
	}
	else {
		printf("\n>>>>>> O.K. Final count is %d\n", count );
	}
}

~~~

Analysis: Before main thread join thread t1, `pthread_join( t1, NULL );` . 

If there is no context switch at this time, after `pthread_mutex_unlock( &mutex );
` mutex lock has been unlocked. So, the mutex lock in main thread has no effect to thread t1 and t2 in this case.  there is no effect on t1 and t2.

If there is context switch before `pthread_mutex_unlock( &mutex )`; main thread will switch to wait state, and OS will switch to thread t1, and when t1 execute to `pthread_mutex_lock( &mutex );
` in function increment(), t1 will be put in wait state.
While, main thread is waitting for thread t1 end. So this case, is deadlock.

We can modify the code to below to test it:

~~~cpp
int main( int argc, char ** argv )
{
	int n = 100000000;
	pthread_t t1, t2;
        pthread_attr_t attr;

	pthread_mutexattr_init( &mattr );
	pthread_mutex_init( &mutex, &mattr);

	pthread_mutex_lock( &mutex );

        pthread_attr_init( &attr );
        pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);

	printf("Start Test. Final count should be %d\n", 2 * n );

	// Create threads
	pthread_create( &t1, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);

	pthread_create( &t2, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);


	// Wait until threads are done
	pthread_join( t1, NULL );

	pthread_mutex_unlock( &mutex );

	pthread_join( t2, NULL );

	if ( count != 2 * n ) {
		printf("\n****** Error. Final count is %d\n", count );
		printf("****** It should be %d\n", 2 * n );
	}
	else {
		printf("\n>>>>>> O.K. Final count is %d\n", count );
	}
}

~~~
In the above code, before we unlock the mutex lock, we first `join(t1)`, in main thread. It will make deadlock.

~~~
(gdb) r
Starting program: /Users/Sean/Desktop/lab4-src/mcount
Start Test. Final count should be 200000000

Breakpoint 2, main (argc=1, argv=0x7fff5fbffa58) at count_masterLock.cc:42
42     		pthread_create( &t1, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);
(gdb) n
[New Thread 0x122f of process 9789]
44     		pthread_create( &t2, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);
(gdb) n
[New Thread 0x142b of process 9789]

Thread 1 hit Breakpoint 1, main (argc=1, argv=0x7fff5fbffa58) at count_masterLock.cc:48
48     		pthread_join( t1, NULL );
(gdb) n


^C
Thread 1 received signal SIGINT, Interrupt.
0x00007fff9420410a in __semwait_signal () from /usr/lib/system/libsystem_kernel.dylib
(gdb) n
Single stepping until exit from function __semwait_signal,
       which has no line number information.
       0x00007fff941fe7f2 in cerror () from /usr/lib/system/libsystem_kernel.dylib
       (gdb) n
       Single stepping until exit from function cerror,
       which has no line number information.
       0x00007fff8366f787 in pthread_join () from /usr/lib/system/libsystem_pthread.dylib
       (gdb)
	Single stepping until exit from function pthread_join,
	which has no line number information.

	n
	^C
	Thread 1 received signal SIGINT, Interrupt.
	0x00007fff9420410a in __semwait_signal () from /usr/lib/system/libsystem_kernel.dylib
	(gdb)
	Single stepping until exit from function __semwait_signal,
	which has no line number information.
	0x00007fff941fe7f2 in cerror () from /usr/lib/system/libsystem_kernel.dylib
	(gdb)
	Single stepping until exit from function cerror,
	which has no line number information.
	0x00007fff8366f787 in pthread_join () from /usr/lib/system/libsystem_pthread.dylib
	(gdb)
	Single stepping until exit from function pthread_join,
	which has no line number information.
~~~
