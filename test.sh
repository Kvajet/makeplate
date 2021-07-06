#!/bin/bash

ARGS_DATA="\
none:generates dependencies based on on files in \"src\" source files;\
-help:prints help;\
-full:initializes Makefile, \"src\" folder and main.cpp;\
-full-c:  initializes Makefile, \"src\" folder and main.c;\
-full-cpp:initializes Makefile, \"src\" folder and main.cpp;\
-c:creates .c or .cpp file based on main extension, also tries to find .h file and if found, generates include;\
-h:creates .h file, creates class if name starts with C, creates struct if name starts with T;\
-ch:creates .c/.cpp and .h file with include, creates class if name start with C, creates struct if name starts with T\
"

# `NONE`      - does current `makeplate` functionality
# `-full`     - creates `Makefile`, `src` folder, `main.cpp` with main() where default is `cpp`
# `-full-c`
# `-full-cpp` - acts same as `-full`

# `-h`        - creates `.h` file with given name
# `-c`        - creates `.cpp` file with given name, if `.h` with same name exists, adds `#include`
# `-ch`       - creates `.h` and `.cpp` file with given name with `#include`

#### COMMON FUNCTIONS ####

error() {
    echo "ERROR: $1 Run -help for more information."
    exit 1
}

warning() {
    echo "WARNING: $1 But it works anyway."
}

args_template() {
    ARGS_TEMPLATE="^$"
    for arg in $( tr ';' '\n' <<< "$ARGS_DATA" | tail -n +2 | cut -d':' -f1 )
    do
        ARGS_TEMPLATE="$ARGS_TEMPLATE\|^$arg\$"
    done
}

separate_args() {
    ARGS_CMD=""
    ARGS_OTH=""
    for arg in $@
    do
        if [[ $arg == -* ]]
        then
            ARGS_CMD="$ARGS_CMD $arg"
        else
            ARGS_OTH="$ARGS_OTH $arg"
        fi
    done
}

validate_arguments() {
    ARGS_CMD="$@"
    if [ $( wc -w <<< $ARGS_CMD ) -gt 1 ]
    then
        error "Invalid number of arguments."
    fi

    args_template
    for arg in $@
    do
        grep_res=$( grep -e "$ARGS_TEMPLATE" <<< "$arg" | wc -l )
        if [ $grep_res -ne 1 ]
        then
            error "Invalid argument \"$arg\"."
        fi
    done
}

# accepts $1 = list of options, $2 = how many should there be, $3 = is forbidden
validate_argument_options() {
    OPT_CNT=$( wc -w <<< "$1" )

    if [ $OPT_CNT -lt $2 ]
    then
        error "Invalid number of options for this argument."
    fi

    if [ $OPT_CNT -ne $2 ]
    then
        if [ $3 -eq 1 ]
        then
            error "Invalid number of options for this argument."
        else
            warning "Invalid number of options. Expected: $2, got: $OPT_CNT."            
        fi
    fi
}

create_src_dir() {
    if ! [ -d "src" ]
    then
        mkdir "src"
    fi
}

dir_exists() {
    if ! [ -d "src" ]
    then
        error "\"src\" directory doesn't exist."
    fi
}

main_exists() {
    dir_exists

    CNT="$( ls src | grep '^main.c$\|^main.cpp$' | wc -l )"
    if [ "$CNT" -lt 1 ]
    then
        error "main.c/main.cpp doesn't exists."
    fi

    if [ "$CNT" -gt 1 ]
    then
        error "Both main.c and main.cpp exist."
    fi
}

trim_and_delete_ext() {
    BUFFER="$( sed -E 's/^\s([^\s].*)$/\1/' <<< $1 )" # trim begin
    BUFFER="$( sed -E 's/\.(h|c|cpp)$//' <<< $BUFFER )"  # delete possible .h
}

# accepts $1 = 0 - c, other - cpp
create_main_file() {
    if [ $( ls src | grep "^main.c$\|^main.cpp$" | wc -l ) -eq 1 ]
    then
        error "Unable to initialize, main.c/main.cpp already exists."
    fi

    if [ $1 -eq 0 ]
    then
        MAIN="src/main.c"
        printf "#include <stdio.h>\n\n" > "$MAIN"
    else
        MAIN="src/main.cpp"
        printf "#include <iostream>\n\n" > "$MAIN"
    fi

    printf "int main( void )\n{\n\n\n\treturn 0;\n}\n" >> "$MAIN"
}

# gets main.c/main.cpp and sets variable VERSION to 0 - C, 1 - CPP
c_or_cpp() {
    dir_exists
    main_exists

    EXT="$( ls src | grep '^main\..*' | sed -E 's/^.*\.(cpp|c)$/\1/' )"
    if [ "$EXT" = "c" ]
    then
        VERSION=0
    elif [ "$EXT" = "cpp" ]
    then
        VERSION=1
    else
        error "Invalid main file."
    fi
}

# none parameter
param-makeplate() {
    echo "DOING MAKEPLATE"
}

# -c parameter
param-c() {
    echo "DOING C"

    dir_exists
    c_or_cpp

    trim_and_delete_ext "$1"
    if [ "$VERSION" -eq 0 ]
    then
        CFILE="$BUFFER.c"
    elif [ "$VERSION" -eq 1 ]
    then
        CFILE="$BUFFER.cpp"
    fi

    if [ -f "src/$CFILE" ]
    then
        error "File with this name already exists."
    fi

    touch "src/$CFILE"

    if [ -f "src/$BUFFER.h" ]
    then
        printf "#include \"$BUFFER.h\"\n" >> "src/$CFILE"
    fi
}

# -h parameter
# accepts $1 = name
param-h() {
    echo "DOING H"

    dir_exists
    trim_and_delete_ext "$1"

    NAME="$BUFFER"
    UPPER="$( tr '.' '_' <<< ${NAME^^}.H )"

    if [ $( ls src | grep "^$NAME.h$" | wc -l ) -eq 1 ]
    then
        error "File name $NAME already exists."
    fi

    printf "#ifndef $UPPER\n#define $UPPER\n\n\n\n#endif // $UPPER\n" > "src/$NAME.h"
}

# -ch parameter
param-ch() {
    echo "DOING CH"

    param-h "$1"
    param-c "$1"
}

# -help parameter
# temporary solution, needs some love
param-help() {
    PARSED="$( tr ';' '\n' <<< "$ARGS_DATA" )"
    sed -E 's/([^:]):([^:])/\1\t\2/' <<< "$PARSED"
}

# -full-c parameter
param-full-c() {
    echo "DOING FULL-C"
    
    create_src_dir
    create_main_file 0
    param-makeplate
}

# -full-cpp parameter
param-full-cpp() {
    echo "DOING FULL-CPP"

    create_src_dir
    create_main_file 1
    param-makeplate
}

# accepts $1 = ARGS_CMD, $2 = ARGS_OTH
parameters() {
    case "$1" in
        "-c")
            validate_argument_options "$2" 1 1
            param-c "$2"
            ;;
        "-ch")
            validate_argument_options "$2" 1 1
            param-ch "$2"
            ;;
        "-h")
            validate_argument_options "$2" 1 1
            param-h "$2"
            ;;
        "-help")
            validate_argument_options "$2" 0 0
            param-help
            ;;
        "-full")
            validate_argument_options "$2" 0 0
            param-full-cpp
            ;;
        "-full-c")
            validate_argument_options "$2" 0 0
            param-full-c
            ;;
        "-full-cpp")
            validate_argument_options "$2" 0 0
            param-full-cpp
            ;;
        *)
            validate_argument_options "$2" 0 0
            param-makeplate
            ;;
    esac
}

#### MAIN FUNCTIONALITY ####

separate_args $@
validate_arguments $ARGS_CMD
parameters "$ARGS_CMD" "$ARGS_OTH"
