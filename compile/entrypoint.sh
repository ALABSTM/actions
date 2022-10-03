#!/bin/bash

# Read the arguments passed through
#  <calling_repo>/.github/workflows/<workflow>/action.yml
readonly  GCC_URL="$1"
readonly  STM32_SERIES="$2"
readonly  DEFINES="$3"
readonly  OPTIONS="$4"

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
# Save the path to executable of the compiler in PATH variable and broaden its
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

# Each iteration, get current source file name in variable "source" to use it
#  with "echo" and "gcc" commands.
for source in "${HAL_DIR}/Src"/*.c
do
    # Log message to the user.
    echo "Compiling $source"
    # Use option -c to stop build at compile- or assemble-level.
    arm-none-eabi-gcc $OPTIONS $DEFINES $INCLUDES -c $source
    # In case compilation fails, stop the loop and do not compile remaining files.
    if [ $? != 0 ] ; then exit 1; fi
done
