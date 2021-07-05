#!/bin/bash

CXX="g++"
CXXFLAGS="-std=c++17 -Wall -Wextra -pedantic -g"
TARGET=$( basename "$PWD" )

if [ ! -d 'src' ]
then
    mkdir 'src'
fi

includes=$( g++ -MM src/*.cpp )
tomake=$( echo "$includes" | tr '\n' '#' | sed 's/\\#/ /g' | tr '#' '\n' | tr -s ' ' | sed -E 's/(.*)/$(BUILD_DIR)\/\1/' | sed -E 's/([a-zA-Z0-9]*\.o).*/\1/' | tr '\n' ' ' )
includes=$( echo "$includes" | tr '\n' '#' | sed 's/\\#/ /g' | tr '#' '\n' | tr -s ' ' | sed -E 's/(.*)/$(BUILD_DIR)\/\1/' )

echo "
CXX=${CXX}
CXXFLAGS=${CXXFLAGS}
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

\$(TARGET): ${tomake}
	\$(CXX) \$(CXXFLAGS) $^ -o \$@

\$(BUILD_DIR)/%.o: src/%.cpp
	\$(MKDIR) \$(BUILD_DIR)
	\$(CXX) \$(CXXFLAGS) -c \$< -o \$@

# .o patterns
${includes}
" > Makefile
