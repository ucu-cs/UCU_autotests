# Tests for myshell
These tests consists of 2 python-scripts *check.py* and *generate_output.py*. check.py uses generate_output.py to perform commands in myshell and then check.py checks them.
<br><br>
Here are also *test_1.msh* and *test_2.msh* that are needed to check how myshell works with myshell-scripts

## Usage

To run tests use command
```
python3 check.py <path-to-myshell>
```

## Important
To perform tests you should also add in folder with your executable with name "prgname" for this code:
```
#include <iostream>
int main(int argc, char *argv[] ){
    cout << "Arguments: " << argc << endl;
    for(int i=0; i<argc; ++i)
        std::cout << "Argument " << i << ": " << argv[i] << std::endl;   
    return 0;
}
```

## Notes
If you want to add testcases or modify existing - change list COMMANDS in *generate_output.py* and add or modify existing checks in *check.py*

