#!/bin/bash

# COLORS -----------------------------------------------------------------------

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'

# Read the arguments passed through
#  <calling_repo>/.github/workflows/<workflow>/action.yml
readonly  GCC_URL="$1"
readonly  STM32_SERIES="$2"
readonly  OPTIONS="$3"

readonly  CMSIS_DIR="./Drivers/CMSIS/Device/ST/STM32${STM32_SERIES}xx"
readonly  HAL_DIR="./Drivers/STM32${STM32_SERIES}xx_HAL_Driver"
readonly  INCLUDES="-I./Drivers/CMSIS/Include -I${CMSIS_DIR}/Include -I${HAL_DIR}/Inc -I./CI/build"

# INSTALL REQUIRED PACKAGES ----------------------------------------------------

# Download "arm-eabi-gcc" compiler and install it...

# Create a dedicated folder to extract the archive into
# mkdir 'make directory', -p 'make parent directories as needed'
mkdir -p ./Utilities/PC_Software/arm-eabi-gcc-toolchain
cd       ./Utilities/PC_Software/arm-eabi-gcc-toolchain
# wget 'get from the Web', -q 'quiet, avoid printing log',
#                          -O filename 'specify name of destination file'
wget -q -O gcc.tar.bz2 $GCC_URL
# tar 'tape archiver', -j 'use Bzip compression', -x 'eXtract archive',
#                      -f 'use File given as parameter'
tar -jxf gcc.tar.bz2 --strip=1
# Save the path to compiler's executable file in PATH variable and broaden its
#  scope to all environments
export PATH=$PWD/bin:$PATH
cd -
# in case arm-none-eabi-gcc compiler is not installed, install it.
arm-none-eabi-gcc --version

# LAUNCH COMPILATION -----------------------------------------------------------

# Copy file stm32$..xx_hal_conf_template.h and rename it stm32$..xx_hal_conf.h
#  as needed for the compilation step.
#  NOTE: ${STM32_SERIES,,} to convert to lower case.
cp "${HAL_DIR}/Inc/stm32${STM32_SERIES,,}xx_hal_conf_template.h" "${HAL_DIR}/Inc/stm32${STM32_SERIES,,}xx_hal_conf.h"

# Point to the CMSIS Device Include directory where the header files
cd "${CMSIS_DIR}/Include"

# Get the different devices' part-numbers from the header filenames
#  NOTE: ${STM32_SERIES,,} to convert to lower case.
#  NOTE: grep options, -P 'pattern is a Perl regex', -o 'output result'
#  NOTE: regex, (?<=\() '(?<=<char>) --> pick what is found after a <char> character, with <char> being an opening parehtesis --> "\("'
#               (?=\))  '(?=<char>)  --> pick what is found before a <char> character, with <char> being a closing parehtesis --> "\)"'
#               .*?     '. --> any character, * --> 0 or more occurences, ? --> 0 or 1 occurrence (of .*)'
# NOTE: in the regex, the ? in .*? ensures each sequence of characters in an expression like "(<string_a>) (<string_b>)" are extracted separately.
#       - .*? --> <string_a>
#                 <string_b>
#       - .*  --> <string_a> (<string_b>)
devices=`cat "stm32${STM32_SERIES,,}xx.h" | grep "\!defined (STM32${STM32_SERIES}.\+)" | grep -Po "(?<=\().*?(?=\))"`

# Point back to the repository's root
cd -

# Initialize the job status
status=0

# Iterate upon the different devices' part-numbers
for device in $devices
do
    # Get the current device's part-number in a variable
    DEFINES='-D'${device}
    echo "Compiling sources for device ${device} **************************" ;
    # For each source file, get current source file name in variable "source"
    #  to use it with "echo" and "gcc" commands.
    for source in "${HAL_DIR}/Src"/*.c
    do
        # Log message to the user.
        #   NOTE: '-e' to enable interpretation of backslash escapes.
        echo -e "\tCompiling " $source
        # Use option -c to stop build at compile- or assemble-level.
        arm-none-eabi-gcc $OPTIONS $DEFINES $INCLUDES -c $source
        # In case compilation fails, abort it for the current part-number and
        #  start it for the next one.
        if [ $? != 0 ] ; then echo -e "\t${RED}KO"; status=1; else echo -e "\t${GREEN}OK"; fi
    done
done

# Return error code in case of failure
if [ $status != 0 ] ; then exit 1; fi
