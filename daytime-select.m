
#include "config.h"

#include <sys/types.h>
#include <sys/socket.h>		/* socket, bind, listen, accept */
#include <sys/select.h>		/* select */

#include <strings.h> 		/* bzero */
#include <stdlib.h> 		/* exit */
#include <unistd.h> 		/* read */

#include <objpak.h> 		/* Objective-C */

#define MAXLINE 4096

#define LISTENQ SOMAXCONN

int main(int argc,char **argv)
{
  id c;
  int i,maxi,maxfd;
  int listenfd,sockfd,connfd;
  char buff[MAXLINE + 1];
  struct sockaddr_in servaddr;
  struct sockaddr_in cliaddr;
  time_t ticks;
  fd_set rset,allset;
  int nready,client[FD_SETSIZE];
  unsigned int clilen;

  if ((listenfd=socket(AF_INET,SOCK_STREAM,0))<0) {
     fprintf(stderr,"socket error\n");
  }

  bzero(&servaddr,sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY); 
  servaddr.sin_port = htons(13); /* daytime server */

  if (bind(listenfd,(const struct sockaddr *)&servaddr,sizeof(servaddr)) < 0) {
     fprintf(stderr,"bind error\n");
     exit(1);
  }

  if (listen(listenfd,LISTENQ) < 0) {
     fprintf(stderr,"listen error\n");
  }

  FD_ZERO(&allset);
  FD_SET(listenfd,&allset);

  for(;;) {
    rset = allset;
    nready = select(listenfd+1,&rset,NULL,NULL,NULL);

    printf("select %i\n",nready);

    if (FD_ISSET(listenfd,&rset)) { /* new client connection */
       clilen = sizeof (cliaddr);
       connfd = accept(listenfd,(struct sockaddr *)&cliaddr,&clilen);

       printf("accept\n");

       ticks = time(NULL);
       snprintf(buff, sizeof(buff), "%.24s\r\n", ctime(&ticks));

       if (write(connfd,buff, strlen(buff)) < 0) {
            fprintf(stderr,"write error\n");
       }

       if (close(connfd) < 0) {
          fprintf(stderr,"close error\n");
       }
    }
  }
}

