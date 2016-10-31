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






