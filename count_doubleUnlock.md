# Double or Multiple Unlock MutexLock

## 1. Double Unlock

code:

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
		pthread_mutex_unlock( &mutex );
}

int main( int argc, char ** argv )
{
	int n = 5;
	//int n = 20000000;
	pthread_t t1, t2;
        pthread_attr_t attr;

	pthread_mutexattr_init( &mattr );
	pthread_mutex_init( &mutex, &mattr);

        pthread_attr_init( &attr );
        pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);

	printf("Start Test. Final count should be %d\n", 2 * n );

	// Create threads
	pthread_create( &t1, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);

	pthread_create( &t2, &attr, (void * (*)(void *)) increment, (void *) (size_t) n);

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

Unlock mutexLock twice, when `n = 5`, most times, the result will be OK, still 10.
	But when `n = 100000000`, a lot of switch between threads happen, the result will not be correct, less than 200000000, like 123160000.



## 2. Multiple Unlock
	
code:

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
		pthread_mutex_unlock( &mutex );
		pthread_mutex_unlock( &mutex );
~~~

The above code unlock `ntimes+2` times;. even when `n = small numbers`, the result will be not correct.
