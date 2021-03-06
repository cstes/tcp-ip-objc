# tcp-ip-objc
Test programs for TCP/IP programming in Objective-C

These programs are intended to be a "test suite" for the Portable Object Compiler (see http://users.telenet.be/stes/compiler.html).

	./configure
	make

to build them.  The Makefile uses "objc" so first install objc.

They are essentially plain C programs, using the elementary socket interface,
from the "Berkeley Unix" API.

Instead of using .c C program suffix, we put them in a .m file.

The programs correspond roughly to W.Richard Stevens' UNIX Network Programming
(2nd edition, Prentice Hall), but they also contain some Objective-C uses.

The Objective-C compiler is then forced to work in "C compatibility" mode,
and must include the standard #include files.

So building (compiling) those .m files is a test for parsing system headers,
such as: <sys/types.h>, <sys/socket.h>, <netdb.h> and so on.

The goal is to be able to mix Objective-C and C language constructs,
but for this to work, we must make sure that we can parse the regular C files.

For some of the programs to work, enable the necessary services.
For example on Solaris you may have to do:

svcadm enable svc:/network/daytime:stream
svcadm enable svc:/network/daytime:dgram

so that the "daytime" and "daytime-dgram" programs can connect to the daytime port (13).

Or run the simple daytime-server.m , as an alternative (for TCP).

David Stes

