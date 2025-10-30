import subprocess, sys, os, time

# COUNTER = 0
redirect_file = "./myfile1.txt"

def execute_command(command):
    # print(command)
    process.stdin.write(f'{command}\n'.encode('ascii'))
    # print(process.stdout)


args = sys.argv

path_to_myshell = args[1]

if path_to_myshell.rsplit('/')[-1] != 'myshell':
    print("❗ You've got a problem with your executable name: -2 points")

current_path = os.getcwd()

process = subprocess.Popen(" ".join([path_to_myshell, ">", redirect_file]), shell=True, stdin=subprocess.PIPE)

COMMANDS = [
    '',

    '/bin/ls',
    '/bin/echo hi',
    'mecho my hi 2',

    'ls',
    'echo hi',

    'prgname arg1 arg2 arg3=4',

    "\x1B[A",

    'cat *.msh',

    "mexport VAR=ABC",
    "/bin/echo $VAR",

    "mexport VAR=123",
    "mecho $VAR",

    'mecho hi #friend',
    'mecho hi#friend',

    './test_1.msh',

    '. ./test_1.msh',
    '. ./test_2.msh',

    '/bin/ls',
    'merrno',

    'mpwd',
    'mcd ..',
    'mpwd',
    f'mcd {current_path}',
    'mpwd',

    'mecho 123',
    'mecho 321 #not',

    'mycat ./test_2.msh',

    '',
]

for command in COMMANDS:
    # print(command)
    execute_command(command)
