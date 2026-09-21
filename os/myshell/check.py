import subprocess, sys, os, time

args = sys.argv

if len(args) != 2:
    print("Invalid usage of tests.\nShould be python3 check.py <path-to-myshell>")
    sys.exit(1)

path_to_myshell = args[1]

if path_to_myshell.rsplit('/')[-1] != 'myshell':
    print("❗ You've got a problem with your executable name: -2 points")

process = subprocess.run(" ".join(['python3', 'generate_output.py', path_to_myshell]), shell=True)

redirect_file = "./myfile1.txt"

time.sleep(1)

with open(redirect_file, 'r') as file:
    file.close()

with open(redirect_file, 'r', encoding='UTF-8') as file:
    con = [line[:-1] for line in file.readlines()]

def analyze_output(output):

    outputs = []
    this_output = []
    current_command = ''

    for line in output:

        if ' $ ' in line:

            # print(len(this_output), line)
            if len(outputs) == 0:
                current_command = line

            splitted = current_command.split(' $ ')

            outputs.append({'path': splitted[0],'command': splitted[1], "output": this_output})
            # print(outputs)
            this_output = []

            current_command = line

        elif len(outputs) != 0:
            this_output.append(line)

    outputs = outputs[1:]

    for idx, output_ in enumerate(outputs):
        print(f'{idx}: {output_}')

    return outputs

processed_output = analyze_output(con)
COUNTER = 0

def check_one_command(expected_output, expected_command=None, expected_path=None):
    global COUNTER

    if COUNTER >= len(processed_output):
        print('Something went wrong, more command checks than inputs')
        sys.exit(2)

    actual_output = processed_output[COUNTER]['output']
    # print(repr(actual_output))

    if actual_output != expected_output:
        print("Actual:", actual_output)
        print("Expected:", expected_output)
        print(f'failed at {processed_output[COUNTER]["command"]}')

    if expected_command:

        actual_command = processed_output[COUNTER]['command']

        if expected_command != actual_command:
            # print("Actual:", actual_command)
            # print("Expected:", expected_command)

            print("You've got a problem")

    COUNTER += 1


print("Prompt check")
check_one_command([], None, os.getcwd() + " $ ")

print("ls, echo, and mecho check")

process_1 = subprocess.run('/bin/ls', shell=True, capture_output=True, text=True)
expected_ls = process_1.stdout.split()
check_one_command(expected_ls)

check_one_command(["hi"])
check_one_command(["my hi 2"])


print("PATH check")
check_one_command(expected_ls)
check_one_command(["hi"])

print("args check")
check_one_command([])

print("History check")
check_one_command([], processed_output[COUNTER-1]['command'])

print("wildcard check")
process_2 = subprocess.run('cat *.msh', shell=True, capture_output=True, text=True)
expected = process_2.stdout[:-1].split('\n')
check_one_command(expected)

print("Variabels check")
check_one_command([])
check_one_command(["ABC"])

check_one_command([])
check_one_command(["123"])

print("Comment check")
check_one_command(["hi"])
check_one_command(["hi"])

print("Current script check")
check_one_command(["hi", os.getcwd()])

print("Child script check")
check_one_command(["hi", os.getcwd()])

print("Comment and env. vars check in script")
check_one_command(['123'])

print("merrno check")
check_one_command(expected_ls)
check_one_command(['0'])

print("mpwd and mcd check")
remember_path = os.getcwd()
check_one_command([remember_path])
check_one_command([])
check_one_command([remember_path.rsplit('/', maxsplit=1)[0]])
check_one_command([])
check_one_command([remember_path])

print("mecho")
check_one_command(['123'])

print("mecho with comment")
check_one_command(['321'])

print("mycat check")
process_2 = subprocess.run('cat ./test_2.msh', shell=True, capture_output=True, text=True)
expected = process_2.stdout[:-1].split('\n')
check_one_command(expected)