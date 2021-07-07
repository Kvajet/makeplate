# makeplate

This script is tool for fast initializing .c or .cpp projects, .h and .cpp files.

## How to use it?

- `none` - generates dependencies based on on files in "src" source files by calling `gcc -MM src/*.c` or `g++ -MM src/*.cpp`, depending on presence of `main.c` or `main.cpp`
- `-help` - prints help
- `-full` - initializes Makefile, "src" folder, main.cpp (including simple main function) and .gitignore
- `-full-c` - initializes Makefile, "src" folder, main.c (including simple main function) and .gitignore
- `-full-cpp` - initializes Makefile, "src" folder, main.cpp (including simple main function) and .gitignore
- `-c [filename]` - creates .c or .cpp file based on main extension, also tries to find .h file and if found, generates include, if the name meets requirement `T[A-Z].*`, generates structure named as filename, if main.cpp is present and the name meets requirement `C[A-Z].*`, generates class named as filename with correspoding constructor
- `-h [filename]` - creates .h file, creates class if name starts with C, creates struct if name starts with T
- `-ch [filename]` - creates .c/.cpp and .h file with include, creates class if name start with C, creates struct if name starts with T

## But why?

I do like console, compiling in console and console running the program in console. I was slowed by creating files by myself, therefore I wrote this script.

## Can I use it?

Sure, feel free to take it and modify it as you wish.

## Warning

This program is tested by me. BUT, there is possibility that makeplate.sh contains bugs and causes some unwanted behaviour. Therefore the usage of this software is your choice and I do not take any responsibility for any caused damage. I don't think it will delete source code or anything, it's replacing Makefile and creates main.c/main.cpp. But I had to say it.
