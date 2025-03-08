import curses
import os


def main(stdscr):
    # Initialize curses
    curses.curs_set(0)
    stdscr.clear()
    
    # Set ESCDELAY to reduce delay for ESC key
    os.environ.setdefault("ESCDELAY", "25")

    # parse config files
    directory = "cfg"
    files = []
    values = []
    # iterate over files
    for filename in os.listdir(directory):
        f = os.path.join(directory, filename)
        # checking if it is a file
        if os.path.isfile(f):
            print(f)
            files.append(f[len(directory)+1:])
            file = open(f, "r")
            value = file.read().splitlines()[0]
            file.close()
            values.append(value)
    config = dict(zip(files, values))

    current_selection = 0

    while True:
        stdscr.clear()
        height, width = stdscr.getmaxyx()

        # Display title
        title = "tea2adt configuration"
        stdscr.addstr(0, (width - len(title)) // 2, title, curses.A_BOLD)

        # Display options
        for i, (key, value) in enumerate(config.items()):
            y = i + 2
            if i == current_selection:
                stdscr.attron(curses.A_REVERSE)
            try:
                stdscr.addstr(y, 2, f"{key:<30} {value}")
            except curses.error:
                pass
            if i == current_selection:
                stdscr.attroff(curses.A_REVERSE)

        # Display instructions
        stdscr.addstr(height - 2, 2, "Use UP/DOWN to navigate, ENTER to edit, 'q' to quit")

        stdscr.refresh()

        # Handle user input
        key = stdscr.getch()
        if key == ord('q'):
            break
        elif key == curses.KEY_UP:
            current_selection = (current_selection - 1) % len(config)
        elif key == curses.KEY_DOWN:
            current_selection = (current_selection + 1) % len(config)
        elif key == 10:  # Enter key
            # Edit selected option
            curses.echo()
            curses.curs_set(1)
            selected_key = list(config.keys())[current_selection]
            stdscr.addstr(height - 1, 2, f"New value for {selected_key} (ESC to cancel): ")
            stdscr.refresh()
            
            new_value = ""
            while True:
                ch = stdscr.getch()
                if ch == 27:  # ESC key
                    break
                elif ch == 10:  # Enter key
                    if new_value == '': # we also want to be able to enter empty values
                        new_value = "\n\n"
                    config[selected_key] = new_value
                    f = open(directory+"/"+selected_key, "w")
                    f.write(new_value)
                    f.close()
                    break
                elif ch == curses.KEY_BACKSPACE or ch == 127:
                    new_value = new_value[:-1]
                    stdscr.addstr(height - 1, len(f"New value for {selected_key} (ESC to cancel): ") + 2, " " * len(new_value) + " ")
                    stdscr.addstr(height - 1, len(f"New value for {selected_key} (ESC to cancel): ") + 2, new_value)
                else:
                    new_value += chr(ch)
                    # stdscr.addch(ch)
                stdscr.refresh()
            
            curses.noecho()
            curses.curs_set(0)

if __name__ == "__main__":
    curses.wrapper(main)
