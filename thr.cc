#include <stdio.h>
#include <pthread.h>

void prstr( const char *s ){
	while( 1 ){
		printf( "%s",s);
	}
}
int main(){
	// thread 2
	pthread_create( NULL, NULL, (void * (*)(void *)) prstr, (void *) "b\n" );
	// thread 3
	pthread_create(NULL, NULL, (void * (*)(void *)) prstr,(void *) "c\n" );
	// thread 1
	prstr((void *) "a\n" );
}
