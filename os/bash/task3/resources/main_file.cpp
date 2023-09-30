#include <iostream>

#include "file1.h"
#include "file2.h"

int main()
{
	std::cout << "Hello world from main!" << std::endl;
	
	struct X y;
	function_from_file1(y);

	function_from_file2();

	return 0;
}
