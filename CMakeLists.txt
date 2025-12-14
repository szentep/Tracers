add_falcor_executable(Tracers)

target_sources(Tracers PRIVATE
    TracersApp.h
    TracersApp.cpp
)

# add_subdirectory(Shaders)

# add all shaders automatically
file(GLOB_RECURSE SHADER_FILES
	"${CMAKE_CURRENT_SOURCE_DIR}/Shaders/*.slang"
)
target_sources(Tracers PRIVATE ${SHADER_FILES})

target_copy_shaders(Tracers Samples/Tracers)

target_source_group(Tracers "Samples")
