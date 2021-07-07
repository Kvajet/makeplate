#!/bin/bash

ARGS_DATA="\
none:generates dependencies based on on files in \"src\" source files;\
-help:prints help;\
-full:initializes Makefile, \"src\" folder, main.cpp and .gitignore;\
-full-c:initializes Makefile, \"src\" folder,main.c and .gitignore;\
-full-cpp:initializes Makefile, \"src\" folder, main.cpp and .gitignore;\
-c:creates .c or .cpp file based on main extension, also tries to find .h file and if found, generates include;\
-h:creates .h file, creates class if name starts with C, creates struct if name starts with T;\
-ch:creates .c/.cpp and .h file with include, creates class if name start with C, creates struct if name starts with T\
"

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

create_gitignore() {
    if [ -f ".gitignore" ]
    then
        error ".gitignore already exists."
    fi

    TARGET=$( basename "$PWD" )

    printf "\
.vscode
examples
build
$TARGET
" > ".gitignore"
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

# accepts $1 = CSomething
create-class() {
    printf "\
class $1
{
public:
    $1();

private:
};" >> "src/$1.h"
}

# accepts $1 = CSomething
create-struct() {
    printf "\
struct $1
{

};" >> "src/$1.h"
}

# none parameter
param-makeplate() {
    dir_exists
    main_exists
    c_or_cpp

    # makeplate logic

    if [ "$VERSION" -eq 0 ]
    then
        CXX="gcc"
        CXXVERSION="-std=c99"
        INCLUDES=$( gcc -MM src/*.c )
    else
        CXX="g++"
        CXXVERSION="-std=c++17"
        INCLUDES=$( g++ -MM src/*.cpp )
    fi
    
    CXXFLAGS="-Wall -Wextra -pedantic -g"
    LIBS=""
    TARGET=$( basename "$PWD" )
    TOMAKE=$( awk -F':' 'BEGIN { res="" } { res=res" $(BUILD_DIR)/"$1 } END { print res }' <<< "$INCLUDES" )
    INCLUDES=$( awk '{ print "$(BUILD_DIR)/"$0 }' <<< "$INCLUDES" )

echo "\
CXX=${CXX}
CXXFLAGS=${CXXFLAGS}
CXXVERSION=${CXXVERSION}
LIBS=${LIBS}
TARGET=${TARGET}

BUILD_DIR=build
MKDIR=mkdir -p

.PHONY: all
all: compile run

.PHONY: compile
compile: \$(TARGET)

.PHONY: run
run: \$(TARGET)
	./\$(TARGET)

valgrind: \$(TARGET)
	valgrind ./\$(TARGET)

.PHONY: clean
clean:
	@rm -rf \$(BUILD_DIR)/ \$(TARGET) 2>/dev/null

\$(TARGET):${TOMAKE}
	\$(CXX) \$(CXXVERSION) \$(CXXFLAGS) $^ -o \$@ \$(LIBS)

\$(BUILD_DIR)/%.o: src/%.cpp
	\$(MKDIR) \$(BUILD_DIR)
	\$(CXX) \$(CXXFLAGS) -c \$< -o \$@

# .o patterns
${INCLUDES}" > Makefile
}

# -c parameter
param-c() {
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
    dir_exists
    trim_and_delete_ext "$1"
    c_or_cpp

    NAME="$BUFFER"
    UPPER="$( tr '.' '_' <<< ${NAME^^}.H )"

    if [ $( ls src | grep "^$NAME.h$" | wc -l ) -eq 1 ]
    then
        error "File name $NAME already exists."
    fi

    printf "#ifndef $UPPER\n#define $UPPER\n\n" > "src/$NAME.h"

    if [[ "$NAME" == T[A-Z]* ]]
    then
        create-struct "$NAME"
    elif [[ "$NAME" == C[A-Z]* ]] && [ "$VERSION" -eq 1 ]
    then
        create-class "$NAME"
    fi

    printf "\n\n#endif // $UPPER\n" >> "src/$NAME.h"
}

# -ch parameter
param-ch() {
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
    create_src_dir
    create_main_file 0
    param-makeplate
}

# -full-cpp parameter
param-full-cpp() {
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
            param-makeplate
            ;;
        "-ch")
            validate_argument_options "$2" 1 1
            param-ch "$2"
            param-makeplate
            ;;
        "-h")
            validate_argument_options "$2" 1 1
            param-h "$2"
            param-makeplate
            ;;
        "-help")
            validate_argument_options "$2" 0 0
            param-help
            ;;
        "-full")
            validate_argument_options "$2" 0 0
            param-full-cpp
            create_gitignore
            ;;
        "-full-c")
            validate_argument_options "$2" 0 0
            param-full-c
            create_gitignore
            ;;
        "-full-cpp")
            validate_argument_options "$2" 0 0
            param-full-cpp
            create_gitignore
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
