cmake_minimum_required(VERSION 3.18.0 FATAL_ERROR)

# iOS Development requires clang (something is wrong with the clang variables when the target is set)
#k if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
	#k message(FATAL_ERROR "Enzyme requires the use of clang.")
#k endif()


# Set to iphoneos sdk
set(ENZYME_IOS_SDK "/Applications/XCode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk")
# Configuration stuff

set(CMAKE_OSX_ARCHITECTURES "arm64")
set(CMAKE_OSX_SYSROOT ${ENZYME_IOS_SDK})

# Set output folder
set(ENZYME_BIN_FOLDER ${CMAKE_BINARY_DIR}/enzyme_bin)
if (NOT EXISTS ${ENZYME_BIN_FOLDER})
	make_directory(${ENZYME_BIN_FOLDER})
endif()

set(ENZYME_ROOT ${CMAKE_CURRENT_LIST_DIR})
macro(enzyme_setup unzipped_folder binary_name)
	# Perform checks on the IPA
	if (NOT DEFINED ENZYME_UNZIPPED_FOLDER)
		message(FATAL_ERROR "Define ENZYME_UNZIPPED_FOLDER where the unzipped IPA is located.")
	endif()

	if (NOT EXISTS "${ENZYME_UNZIPPED_FOLDER}/Payload")
		message(FATAL_ERROR "Cannot find Payload folder. Place your unzipped IPA file into the folder defined in ENZYME_UNZIPPED_FOLDER.")
	endif()

	file(GLOB ENZYME_APP_FOLDER "${ENZYME_UNZIPPED_FOLDER}/Payload/*.app")

	if(ENZYME_APP_FOLDER STREQUAL "")
		message(FATAL_ERROR "Unable to find application inside Payload folder.")
	endif()

	if (NOT DEFINED ENZYME_BINARY_NAME)
		message(FATAL_ERROR "Unable to determine binary name. Define ENZYME_BINARY_NAME.")
	endif()

	if (NOT EXISTS "${ENZYME_APP_FOLDER}/${ENZYME_BINARY_NAME}")
		message(FATAL_ERROR "Unable to find binary name ${ENZYME_BINARY_NAME} in application folder")
	endif()

	# Codegen target
	add_custom_target(EnzymeCodegen ALL
		COMMAND mkdir -p ${ENZYME_BIN_FOLDER}//IPA
		COMMAND python3 enzyme.py
			${ENZYME_APP_FOLDER}/${ENZYME_BINARY_NAME}
			${ENZYME_BIN_FOLDER}
			${ENZYME_BINARY_NAME}
			${CMAKE_CURRENT_SOURCE_DIR}
		WORKING_DIRECTORY ${ENZYME_ROOT}/patcher
		COMMENT "Creating Patch"
		BYPRODUCTS ${ENZYME_BIN_FOLDER}/bootloader.hpp
	)
	add_dependencies(${PROJECT_NAME} EnzymeCodegen)

	# Our codegen creates a header file for us
	target_include_directories(${PROJECT_NAME} PRIVATE ${ENZYME_BIN_FOLDER})
	target_link_options(${PROJECT_NAME} PRIVATE "-L${ENZYME_IOS_SDK}/usr/lib")
endmacro()

include(${CMAKE_CURRENT_LIST_DIR}/cmake/Package.cmake)
