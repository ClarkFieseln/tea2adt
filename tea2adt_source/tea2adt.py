import sys
import subprocess
from signal import signal, SIGINT, SIGTERM
import os
import pathlib



def get_version():
    # the directory containing this file
    HERE = pathlib.Path(__file__).parent
    # launch path
    # print("launch path = " + str(HERE))
    # the version in the version file
    if "tea2adt" in str(sys.argv):
        __version__ =  (HERE / "version").read_text()[:-1]
    else:
        __version__ =  (HERE / "tea2adt_source/version").read_text()[:-1]
    return __version__

def get_package_installation_path(package_name):
    try:
        result = subprocess.run(['pip', 'show', '-f', package_name], capture_output=True, text=True)
        output = result.stdout.strip()
        if output:
            lines = output.split('\n')
            for line in lines:
                if line.startswith('Location:'):
                    return line.split(':', 1)[1].strip()
        return None
    except FileNotFoundError:
        return None
        
# python wrapper for tea2adt shell script
# in order to use PyPi
##########################################
def main():
    # change path to installation directory
    installation_path = get_package_installation_path("tea2adt")
    if installation_path is not None:
        installation_path = installation_path+"/tea2adt_source"
        os.chdir(installation_path)
        # banner
        print("tea2adt " + get_version())
        print("configuration parameters can be set in folder " + installation_path+"/cfg")
        # open terminal file
        f = open(installation_path+"/cfg/terminal", "r")
    else:
        # banner
        print("tea2adt " + get_version())
        # open terminal file
        f = open("cfg/terminal", "r")
    print("-------------------------------")
    # read configured terminal
    TERMINAL = f.read().splitlines()[0]
    f.close()
    # with the following line, no message or stack trace will be printed when you Ctrl+C this program
    signal(SIGINT, lambda _, __: exit())
    # parse arguments
    #################                    
    if len(sys.argv) > 1:
        try:
            # call tea2adt shell script
            ############################
            if (("tmux" in TERMINAL) and ((sys.argv[1] == "-c") or (sys.argv[1] == "--chat") or (sys.argv[1] == "-s")
                or (sys.argv[1] == "--rs") or (sys.argv[1] == "--remote-shell") or (sys.argv[1] == "--reverse-shell") or (sys.argv[1] == "-f")
                or (sys.argv[1] == "--file") or (sys.argv[1] == "--file-transfer") or (sys.argv[1] == "-p") or (sys.argv[1] == "--probe"))):
                # create a new tmux session where following tmux calls will execute (but only for arguments -c, -s, -f and -p)
                command = "".join(["tmux new-session ./tea2adt '", sys.argv[1], "'"])
            else:
                command = "".join(["./tea2adt '", sys.argv[1], "'"])
            p1 = subprocess.Popen(command, shell=True, stdout=None, text=True)
            '''p1 = subprocess.Popen(command,
                            shell=True,
                            text=True,
                            stdin =subprocess.PIPE,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE # ,
                            # universal_newlines=True,
                            # bufsize=0
                            )'''
            out, err = p1.communicate()
            if p1.returncode == 0:
                p1.terminate()
                p1.kill()
        except:
            # send the SIGTERM signal to all the process groups to terminate processes launched from here
            os.killpg(os.getpgid(p1.pid), SIGTERM)
    else:
        print("tea2adt: *** you must specify an option, run tea2adt -h for more information ***")
    
if __name__ == '__main__':
    main()
