#include <stdio.h>

class Hello {
public:
	Hello(const char *s) { printf(s); }
};

extern "C" void hello()
{
	Hello("Hello C world!\n");
	Hello("Hello C++ world!!\n");
}
