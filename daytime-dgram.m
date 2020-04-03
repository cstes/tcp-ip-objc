
#include "config.h"

#include <sys/types.h>
#include <sys/socket.h>		/* socket, connect, recvfrom */
#include <netinet/in.h>
#include <arpa/inet.h> 		/* inet_pton */

#include <strings.h> 		/* bzero */
#include <stdlib.h> 		/* exit */
#include <unistd.h> 		/* read */

#include <objpak.h> 		/* Objective-C */

#define MAXLINE 4096

#define MYMESSAGE "ignore me"

int main(int argc,char **argv)
{
  id c;
  int sockfd,n;
  int numDgrams = 1;
  char recvline[MAXLINE + 1];
  struct sockaddr_in servaddr;

  if (argc != 2) {
     fprintf(stderr,"usage: a.out <ip-address>\n");
     exit(1);
  }

  if ((sockfd=socket(AF_INET,SOCK_DGRAM,0))<0) {
     fprintf(stderr,"socket error\n");
  }

  c = [OrderedCollection new]; /* Objective-C collection */

  bzero(&servaddr,sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_port = htons(13); /* daytime server */

  if (inet_pton(AF_INET,argv[1],&servaddr.sin_addr) <= 0) {
     fprintf(stderr,"inet_pton error for %s\n",argv[1]);
     exit(1);
  }

  while (numDgrams--) {
    char *s = MYMESSAGE;

    /* send a datagram to the UDP daytime server (it will trigger reply) */
    if (sendto(sockfd,s,strlen(s),0,(const struct sockaddr *)&servaddr,sizeof(servaddr)) < 0) {
     fprintf(stderr,"sendto error\n");
    }

    n=recvfrom(sockfd,recvline,MAXLINE,0,NULL,NULL);
    if (n < 0) {
     fprintf(stderr,"recvfrom error\n");
    }

    recvline[n] = 0;
    [c add:[String str:recvline]];
  }


  printf("Received %i object(s):\n",[c size]);
  for(n=0;n<[c size];n++) {
     printf("Object %i. %s",n,[[c at:n] str]);
  }
  exit(0); 
}

