# bgfx.cmake - bgfx building in cmake
# Written in 2017 by Joshua Brookover <joshua.al.brookover@gmail.com>

# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.

# You should have received a copy of the CC0 Public Domain Dedication along with
# this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

# To prevent this warning: https://cmake.org/cmake/help/git-stage/policy/CMP0072.html
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
endif()

# Ensure the directory exists
if( NOT IS_DIRECTORY ${BGFX_DIR} )
	message( SEND_ERROR "Could not load bgfx, directory does not exist. ${BGFX_DIR}" )
	return()
endif()

if(NOT APPLE)
	set(BGFX_AMALGAMATED_SOURCE ${BGFX_DIR}/src/amalgamated.cpp)
else()
	set(BGFX_AMALGAMATED_SOURCE ${BGFX_DIR}/src/amalgamated.mm)
endif()

# Grab the bgfx source files
file( GLOB BGFX_SOURCES ${BGFX_DIR}/src/*.cpp ${BGFX_DIR}/src/*.mm ${BGFX_DIR}/src/*.h ${BGFX_DIR}/include/bgfx/*.h ${BGFX_DIR}/include/bgfx/c99/*.h )
if(BGFX_AMALGAMATED)
	set(BGFX_NOBUILD ${BGFX_SOURCES})
	list(REMOVE_ITEM BGFX_NOBUILD ${BGFX_AMALGAMATED_SOURCE})
	foreach(BGFX_SRC ${BGFX_NOBUILD})
		set_source_files_properties( ${BGFX_SRC} PROPERTIES HEADER_FILE_ONLY ON )
	endforeach()
else()
	# Do not build using amalgamated sources
	set_source_files_properties( ${BGFX_DIR}/src/amalgamated.cpp PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/amalgamated.mm PROPERTIES HEADER_FILE_ONLY ON )
endif()

add_library(bgfx_private_settings INTERFACE)
add_library(bgfx_public_settings INTERFACE)

# Renderer injection
list(REMOVE_ITEM BGFX_SOURCES ${BGFX_DIR}/src/renderer_d3d11.cpp)
list(REMOVE_ITEM BGFX_SOURCES ${BGFX_DIR}/src/renderer_d3d11.h)
	
add_library(bgfx_inj OBJECT ${BGFX_CPM_ROOT}/src/renderer_injected.cpp ${BGFX_CPM_ROOT}/src/renderer_injected.h)
target_link_libraries( bgfx_inj PRIVATE bgfx_private_settings PUBLIC bgfx_public_settings )
target_include_directories( bgfx_inj PRIVATE ${BGFX_DIR}/src )

# Create the bgfx target
add_library( bgfx ${BGFX_LIBRARY_TYPE} ${BGFX_SOURCES} $<TARGET_OBJECTS:bgfx_inj>)

target_link_libraries( bgfx PRIVATE bgfx_private_settings bgfx_inj PUBLIC bgfx_public_settings )

target_link_libraries( bgfx PRIVATE bgfx_inj)

if(BGFX_CONFIG_RENDERER_WEBGPU)
    include(cmake/3rdparty/webgpu.cmake)
    target_compile_definitions( bgfx_private_settings INTERFACE BGFX_CONFIG_RENDERER_WEBGPU=1)
    if (EMSCRIPTEN)
        target_link_options(bgfx_private_settings INTERFACE "-s USE_WEBGPU=1")
    else()
        target_link_libraries(bgfx_private_settings INTERFACE webgpu)
    endif()
endif()

# Enable BGFX_CONFIG_DEBUG in Debug configuration
target_compile_definitions( bgfx_private_settings INTERFACE "$<$<CONFIG:Debug>:BGFX_CONFIG_DEBUG=1>" )
if(BGFX_CONFIG_DEBUG)
	target_compile_definitions( bgfx_private_settings INTERFACE BGFX_CONFIG_DEBUG=1)
endif()

if( NOT ${BGFX_OPENGL_VERSION} STREQUAL "" )
	target_compile_definitions( bgfx_private_settings INTERFACE BGFX_CONFIG_RENDERER_OPENGL_MIN_VERSION=${BGFX_OPENGL_VERSION} )
endif()

if( NOT ${BGFX_OPENGLES_VERSION} STREQUAL "" )
	target_compile_definitions( bgfx_private_settings INTERFACE BGFX_CONFIG_RENDERER_OPENGLES_MIN_VERSION=${BGFX_OPENGLES_VERSION} )
endif()

# Special Visual Studio Flags
if( MSVC )
	target_compile_definitions( bgfx_private_settings INTERFACE "_CRT_SECURE_NO_WARNINGS" )
endif()

if( BGFX_CONFIG_RENDERER_WHITELIST )
	if( BGFX_CONFIG_RENDERER_DIRECT3D9 )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_DIRECT3D9=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_DIRECT3D11 )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_DIRECT3D11=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_DIRECT3D12 )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_DIRECT3D12=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_GNM )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_GNM=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_METAL )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_METAL=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_NVN )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_NVN=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_OPENGL )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_OPENGL=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_OPENGLES ) 
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_OPENGLES=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_VULKAN )  
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_VULKAN=1" )
	endif()
	if( BGFX_CONFIG_RENDERER_WEBGPU )
		target_compile_definitions( bgfx_public_settings INTERFACE "BGFX_CONFIG_RENDERER_WEBGPU=1" )
	endif()
endif()

# Includes
target_include_directories( bgfx_private_settings
	INTERFACE
		${BGFX_DIR}/3rdparty
		${BGFX_DIR}/3rdparty/dxsdk/include
		${BGFX_DIR}/3rdparty/khronos)

target_include_directories( bgfx_public_settings
	INTERFACE
		$<BUILD_INTERFACE:${BGFX_DIR}/include>
		$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

# bgfx depends on bx and bimg
target_link_libraries( bgfx_public_settings INTERFACE bx bimg )

# ovr support
if( BGFX_USE_OVR )
	target_link_libraries( bgfx_public_settings INTERFACE ovr )
endif()

# Frameworks required on iOS and macOS
if( IOS )
	target_link_libraries (bgfx_public_settings INTERFACE "-framework OpenGLES  -framework Metal -framework UIKit -framework CoreGraphics -framework QuartzCore")
elseif( APPLE )
	find_library( COCOA_LIBRARY Cocoa )
	find_library( METAL_LIBRARY Metal )
	find_library( QUARTZCORE_LIBRARY QuartzCore )
	mark_as_advanced( COCOA_LIBRARY )
	mark_as_advanced( METAL_LIBRARY )
	mark_as_advanced( QUARTZCORE_LIBRARY )
	target_link_libraries( bgfx_public_settings INTERFACE ${COCOA_LIBRARY} ${METAL_LIBRARY} ${QUARTZCORE_LIBRARY} )
endif()

if( UNIX AND NOT APPLE AND NOT EMSCRIPTEN AND NOT ANDROID )
	find_package(X11 REQUIRED)
	find_package(OpenGL REQUIRED)
	#The following commented libraries are linked by bx
	#find_package(Threads REQUIRED)
	#find_library(LIBRT_LIBRARIES rt)
	#find_library(LIBDL_LIBRARIES dl)
	target_link_libraries( bgfx_public_settings INTERFACE ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
endif()

# Exclude mm files if not on OS X
if( NOT APPLE )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_eagl.mm PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_nsgl.mm PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/renderer_mtl.mm PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Exclude glx context on non-unix
if( NOT UNIX OR APPLE )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_glx.cpp PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Put in a "bgfx" folder in Visual Studio
set_target_properties( bgfx PROPERTIES FOLDER "bgfx" )

# in Xcode we need to specify this file as objective-c++ (instead of renaming to .mm)
if (XCODE)
	set_source_files_properties(${BGFX_DIR}/src/renderer_vk.cpp PROPERTIES LANGUAGE OBJCXX XCODE_EXPLICIT_FILE_TYPE sourcecode.cpp.objcpp)
endif()
