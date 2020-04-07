
#include "config.h"

#include <sys/types.h>
#include <sys/socket.h>		/* socket, bind, listen, accept */
#include <sys/file.h>		/* FASYNC */

#include <strings.h> 		/* bzero */
#include <stdlib.h> 		/* exit */
#include <unistd.h> 		/* read */
#include <fcntl.h>		/* fcntl */

#include <time.h>		/* ctime */
#include <signal.h>		/* signal */
#include <errno.h>		/* EWOULDBLOCK */

#include <objpak.h> 		/* Objective-C */

#define QSIZE 8 
#define MAXDG 4096
#define MAXLINE 4096
#define LISTENQ SOMAXCONN

typedef struct {
	void *dg_data;
	size_t dg_len;
	struct sockaddr *dg_sa;
	socklen_t dg_salen;
} DG;

static DG dg[QSIZE];
static long cntread[QSIZE+1];

static int sockfd;

static int iget;
static int iput;
static int nqueue;
static socklen_t clilen;

void sig_io(int signal, siginfo_t * info, void * context)
{
  DG *ptr;
  int nread;
  ssize_t len;

  for(nread=0;;) {
    if (nqueue>=QSIZE) {
      printf("receive overflow\n");
      exit(0);  
    }

    ptr = &dg[iput];
    ptr->dg_salen = clilen;
    len = recvfrom(sockfd,ptr->dg_data,MAXDG,0,ptr->dg_sa,&ptr->dg_salen);
    if (len < 0) {
      if (errno == EWOULDBLOCK) break;else printf("recvfrom error\n");
    }
    ptr->dg_len = len;
  
    nread++;
    nqueue++;
    if (++iput >= QSIZE) iput = 0; 
  }

  cntread[nread]++;
}

void sig_hup(int signal, siginfo_t * info, void * context)
{
  int i;
  for(i=0;i<=QSIZE;i++) printf("cntread[%d] = %ld\n",i,cntread[i]);
}

void dg_echo(struct sockaddr *pcliaddr,socklen_t clilen_arg)
{
  int i,flags;
  time_t ticks;
  const int on = 1;
  char buff[MAXLINE + 1];
  sigset_t zeromask,newmask,oldmask;
  struct sigaction sig_action;
  struct sigaction old_action;

  for(i=0;i<QSIZE;i++) {
    dg[i].dg_data = malloc(MAXDG);
    dg[i].dg_sa = malloc(clilen);
    dg[i].dg_salen = clilen;
  }

  iget=iput=nqueue = 0;

  printf("installing signal handlers\n");

  memset(&sig_action, 0, sizeof(sig_action));
  sig_action.sa_sigaction = sig_hup;
  sig_action.sa_flags = SA_RESTART | SA_SIGINFO;
  sigemptyset(&sig_action.sa_mask);

  sigaction(SIGHUP, &sig_action, &old_action);

  memset(&sig_action, 0, sizeof(sig_action));
  sig_action.sa_sigaction = sig_io;
  sig_action.sa_flags = SA_RESTART | SA_SIGINFO;
  sigemptyset(&sig_action.sa_mask);

  sigaction(SIGIO, &sig_action, &old_action);

  if (fcntl(sockfd,F_SETOWN,getpid())<0) {
   printf("fcntl F_SETOWN failed\n");
  }

  flags = fcntl(sockfd,F_GETFL,0);
  if (flags == -1) {
   printf("fcntl F_GETFL failed\n");
  }

  /* can also use FNDELAY instead of O_NONBLOCK */
  if (fcntl(sockfd,F_SETFL,flags | O_NONBLOCK | FASYNC) < 0) {
   printf("fcntl O_NONBLOCK | FASYNC failed\n");
  }

  sigemptyset(&zeromask);
  sigemptyset(&oldmask);
  sigemptyset(&newmask);
  sigaddset(&newmask,SIGIO);
  sigprocmask(SIG_BLOCK,&newmask,&oldmask);

  for(;;) {

    while (nqueue == 0) sigsuspend(&zeromask);

    sigprocmask(SIG_SETMASK,&oldmask,NULL);

    ticks = time(NULL);
    snprintf(buff, sizeof(buff), "%.24s\r\n", ctime(&ticks));
    if (sendto(sockfd,buff,strlen(buff),0,dg[iget].dg_sa,dg[iget].dg_salen)<0) {
     fprintf(stderr,"sendto error\n");
    }

    if (++iget >= QSIZE) iget = 0;

    sigprocmask(SIG_BLOCK,&newmask,&oldmask);
    nqueue--;
  } 
}

int main(int argc,char **argv)
{
  id c;
  struct sockaddr_in servaddr,cliaddr;

  c = [Object new];

  if ((sockfd=socket(AF_INET,SOCK_DGRAM,0))<0) {
     fprintf(stderr,"socket error\n");
  }

  bzero(&servaddr,sizeof(servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY); 
  servaddr.sin_port = htons(13); /* daytime server */

  if (bind(sockfd,(const struct sockaddr *)&servaddr,sizeof(servaddr)) < 0) {
     fprintf(stderr,"bind error\n");
     exit(1);
  }

  /* sockfd/clilen globals */
  clilen = sizeof(cliaddr);

  dg_echo((struct sockaddr *)&cliaddr,sizeof(cliaddr));
}

