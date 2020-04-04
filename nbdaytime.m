
#include "config.h"

#include <sys/types.h>
#include <sys/socket.h>		/* socket, connect */
#include <netinet/in.h>
#include <arpa/inet.h> 		/* inet_pton */

#include <strings.h> 		/* bzero */
#include <stdlib.h> 		/* exit */
#include <unistd.h> 		/* read */
#include <fcntl.h>  		/* fcntl */

#include <errno.h>		/* errno , EINPROGRESS */

#include <objpak.h> 		/* Objective-C */

#define MAXLINE 4096

int nbconnect(int sockfd,const struct sockaddr *saptr,socklen_t salen,int nsec)
{
  int flags,n,error;
  socklen_t len;
  fd_set rset,wset;
  struct timeval tval;

  flags = fcntl(sockfd,F_GETFL,0);
  fcntl(sockfd,F_SETFL,flags | O_NONBLOCK);

  error = 0;
  if ((n=connect(sockfd,(struct sockaddr*)saptr,salen))<0)
    if (errno != EINPROGRESS) return -1;

  if (n == 0) goto done;

  FD_ZERO(&rset);
  FD_SET(sockfd,&rset);
  wset = rset;
  tval.tv_sec = nsec;
  tval.tv_usec = 0;

  if ((n=select(sockfd + 1,&rset,&wset,NULL,nsec?&tval:NULL))==0) {
     close(sockfd); 
     errno = ETIMEDOUT;
     return -1;
  }

  if (FD_ISSET(sockfd,&rset) || FD_ISSET(sockfd,&wset)) {
     len=sizeof(error);
     if (getsockopt(sockfd,SOL_SOCKET,SO_ERROR,&error,&len) < 0)
         return -1;
  } else {
     printf("select error: sockfd not set\n");
     exit(1);
  }

  done:
   fcntl(sockfd,F_SETFL,flags);
   if (error) {
     close(sockfd);
     errno = error;
     return -1;
   }

  return 0;
}

int main(int argc,char **argv)
{
  id c;
  int sockfd,n;
  char recvline[MAXLINE + 1];
  struct sockaddr_in servaddr;

  if (argc != 2) {
     fprintf(stderr,"usage: a.out <ip-address>\n");
     exit(1);
  }

  if ((sockfd=socket(AF_INET,SOCK_STREAM,0))<0) {
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

  if (nbconnect(sockfd,(const struct sockaddr *)&servaddr,sizeof(servaddr),0) < 0) {
     fprintf(stderr,"connect error\n");
  }

  while ((n=read(sockfd,recvline,MAXLINE)) > 0) {
    recvline[n] = 0;
    [c add:[String str:recvline]];
  }

  if (n < 0) {
     fprintf(stderr,"read error\n");
  }

  printf("Received %i object(s):\n",[c size]);
  for(n=0;n<[c size];n++) {
     printf("Object %i. %s",n,[[c at:n] str]);
  }
  exit(0); 
}

