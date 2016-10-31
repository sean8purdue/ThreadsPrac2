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

### 2.1





