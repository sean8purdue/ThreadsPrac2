# Bug3.1

Code

~~~cpp
void increment(int ntimes )
{
	for ( int i = 0; i < ntimes; i++ ) {
		pthread_mutex_lock( &mutex );
		int c;

		c = count;
		c = c + 1;

		count = c;
	}
		pthread_mutex_unlock( &mutex );
}

~~~


GDB Result:

~~~
(gdb) r
Starting program: /Users/Sean/Desktop/lab4-src/bcount
Start Test. Final count should be 10
[New Thread 0x1313 of process 8656]
[New Thread 0x1403 of process 8656]

Thread 1 hit Breakpoint 3, main (argc=1, argv=0x7fff5fbffa58) at count_bug.cc:45
45     		pthread_join( t1, NULL );
(gdb) n
[Switching to Thread 0x1313 of process 8656]

Thread 2 hit Breakpoint 1, increment (ntimes=5) at count_bug.cc:12
12     		for ( int i = 0; i < ntimes; i++ ) {
(gdb) n

Thread 2 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:13
13     			pthread_mutex_lock( &mutex );
(gdb)
[Switching to Thread 0x1403 of process 8656]

Thread 3 hit Breakpoint 1, increment (ntimes=5) at count_bug.cc:12
12     		for ( int i = 0; i < ntimes; i++ ) {
(gdb) n

Thread 3 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:13
13     			pthread_mutex_lock( &mutex );
(gdb) n
[Switching to Thread 0x1313 of process 8656]

Thread 2 hit Breakpoint 2, increment (ntimes=5) at count_bug.cc:13
13     			pthread_mutex_lock( &mutex );
(gdb) n

^C
Thread 1 received signal SIGINT, Interrupt.
[Switching to Thread 0x1103 of process 8656]
0x00007fff9420410a in __semwait_signal () from /usr/lib/system/libsystem_kernel.dylib
(gdb) n
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
~~~
