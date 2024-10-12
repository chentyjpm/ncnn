
macro(ncnn_add_arch_opt_layer class NCNN_TARGET_ARCH_OPT NCNN_TARGET_ARCH_OPT_CFLAGS)
    set(NCNN_${NCNN_TARGET_ARCH}_HEADER ${CMAKE_CURRENT_SOURCE_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}.h)
    set(NCNN_${NCNN_TARGET_ARCH}_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}.cpp)

    if(WITH_LAYER_${name} AND EXISTS ${NCNN_${NCNN_TARGET_ARCH}_HEADER} AND EXISTS ${NCNN_${NCNN_TARGET_ARCH}_SOURCE})

        set(NCNN_${NCNN_TARGET_ARCH_OPT}_HEADER ${CMAKE_CURRENT_BINARY_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.h)
        set(NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE ${CMAKE_CURRENT_BINARY_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.cpp)

        add_custom_command(
            OUTPUT ${NCNN_${NCNN_TARGET_ARCH_OPT}_HEADER}
            COMMAND ${CMAKE_COMMAND} -DSRC=${NCNN_${NCNN_TARGET_ARCH}_HEADER} -DDST=${NCNN_${NCNN_TARGET_ARCH_OPT}_HEADER} -DCLASS=${class} -P "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/ncnn_generate_${NCNN_TARGET_ARCH_OPT}_source.cmake"
            DEPENDS ${NCNN_${NCNN_TARGET_ARCH}_HEADER}
            COMMENT "Generating source ${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.h"
            VERBATIM
        )
        set_source_files_properties(${NCNN_${NCNN_TARGET_ARCH_OPT}_HEADER} PROPERTIES GENERATED TRUE)

        add_custom_command(
            OUTPUT ${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE}
            COMMAND ${CMAKE_COMMAND} -DSRC=${NCNN_${NCNN_TARGET_ARCH}_SOURCE} -DDST=${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE} -DCLASS=${class} -P "${CMAKE_CURRENT_SOURCE_DIR}/../cmake/ncnn_generate_${NCNN_TARGET_ARCH_OPT}_source.cmake"
            DEPENDS ${NCNN_${NCNN_TARGET_ARCH}_SOURCE}
            COMMENT "Generating source ${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.cpp"
            VERBATIM
        )
        set_source_files_properties(${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE} PROPERTIES GENERATED TRUE)

        set_source_files_properties(${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE} PROPERTIES COMPILE_FLAGS ${NCNN_TARGET_ARCH_OPT_CFLAGS})

        list(APPEND ncnn_SRCS ${NCNN_${NCNN_TARGET_ARCH_OPT}_HEADER} ${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE})

        # generate layer_declaration and layer_registry file
        set(layer_declaration "${layer_declaration}#include \"layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.h\"\n")
        set(layer_declaration "${layer_declaration}namespace ncnn { DEFINE_LAYER_CREATOR(${class}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}) }\n")

        set(layer_registry_${NCNN_TARGET_ARCH_OPT} "${layer_registry_${NCNN_TARGET_ARCH_OPT}}#if NCNN_STRING\n{\"${class}\", ${class}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}_layer_creator},\n#else\n{${class}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}_layer_creator},\n#endif\n")
    else()
        # no isa optimized version
        if(WITH_LAYER_${name})
            set(layer_registry_${NCNN_TARGET_ARCH_OPT} "${layer_registry_${NCNN_TARGET_ARCH_OPT}}#if NCNN_STRING\n{\"${class}\", ${class}_layer_creator},\n#else\n{${class}_layer_creator},\n#endif\n")
        else()
            set(layer_registry_${NCNN_TARGET_ARCH_OPT} "${layer_registry_${NCNN_TARGET_ARCH_OPT}}#if NCNN_STRING\n{\"${class}\", 0},\n#else\n{0},\n#endif\n")
        endif()
    endif()
endmacro()

macro(ncnn_add_arch_opt_source class NCNN_TARGET_ARCH_OPT NCNN_TARGET_ARCH_OPT_CFLAGS)
    set(NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE ${CMAKE_CURRENT_SOURCE_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}_${NCNN_TARGET_ARCH_OPT}.cpp)

    if(WITH_LAYER_${name} AND EXISTS ${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE})
        set_source_files_properties(${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE} PROPERTIES COMPILE_FLAGS ${NCNN_TARGET_ARCH_OPT_CFLAGS})
        list(APPEND ncnn_SRCS ${NCNN_${NCNN_TARGET_ARCH_OPT}_SOURCE})
    endif()
endmacro()

macro(ncnn_add_layer class)
    string(TOLOWER ${class} name)

    # WITH_LAYER_xxx option
    if(${ARGC} EQUAL 2)
        option(WITH_LAYER_${name} "build with layer ${name}" ${ARGV1})
    else()
        option(WITH_LAYER_${name} "build with layer ${name}" ON)
    endif()

    if(NCNN_CMAKE_VERBOSE)
        message(STATUS "WITH_LAYER_${name} = ${WITH_LAYER_${name}}")
    endif()

    if(WITH_LAYER_${name})
        list(APPEND ncnn_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/layer/${name}.cpp)

        # look for arch specific implementation and append source
        # optimized implementation for armv7, aarch64 or x86
        set(LAYER_ARCH_SRC ${CMAKE_CURRENT_SOURCE_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}.cpp)
        if(EXISTS ${LAYER_ARCH_SRC})
            set(WITH_LAYER_${name}_${NCNN_TARGET_ARCH} 1)
            list(APPEND ncnn_SRCS ${LAYER_ARCH_SRC})
        endif()

        set(LAYER_VULKAN_SRC ${CMAKE_CURRENT_SOURCE_DIR}/layer/vulkan/${name}_vulkan.cpp)
        if(NCNN_VULKAN AND EXISTS ${LAYER_VULKAN_SRC})
            set(WITH_LAYER_${name}_vulkan 1)
            list(APPEND ncnn_SRCS ${LAYER_VULKAN_SRC})
        endif()
    endif()

    # generate layer_declaration and layer_registry file
    if(WITH_LAYER_${name})
        set(layer_declaration "${layer_declaration}#include \"layer/${name}.h\"\n")
        set(layer_declaration "${layer_declaration}namespace ncnn { DEFINE_LAYER_CREATOR(${class}) }\n")

        source_group ("sources\\\\layers" FILES "${CMAKE_CURRENT_SOURCE_DIR}/layer/${name}.cpp")
    endif()

    if(WITH_LAYER_${name}_${NCNN_TARGET_ARCH})
        set(layer_declaration "${layer_declaration}#include \"layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}.h\"\n")
        set(layer_declaration "${layer_declaration}namespace ncnn { DEFINE_LAYER_CREATOR(${class}_${NCNN_TARGET_ARCH}) }\n")

        source_group ("sources\\\\layers\\\\${NCNN_TARGET_ARCH}" FILES "${CMAKE_CURRENT_SOURCE_DIR}/layer/${NCNN_TARGET_ARCH}/${name}_${NCNN_TARGET_ARCH}.cpp")
    endif()

    if(WITH_LAYER_${name}_vulkan)
        set(layer_declaration "${layer_declaration}#include \"layer/vulkan/${name}_vulkan.h\"\n")
        set(layer_declaration "${layer_declaration}namespace ncnn { DEFINE_LAYER_CREATOR(${class}_vulkan) }\n")

        file(GLOB_RECURSE NCNN_SHADER_SRCS "layer/vulkan/shader/${name}.comp")
        file(GLOB_RECURSE NCNN_SHADER_SUBSRCS "layer/vulkan/shader/${name}_*.comp")
        list(APPEND NCNN_SHADER_SRCS ${NCNN_SHADER_SUBSRCS})
        foreach(NCNN_SHADER_SRC ${NCNN_SHADER_SRCS})
            ncnn_add_shader(${NCNN_SHADER_SRC})
        endforeach()

        source_group ("sources\\\\layers\\\\vulkan" FILES "${CMAKE_CURRENT_SOURCE_DIR}/layer/vulkan/${name}_vulkan.cpp")
    endif()

    if(WITH_LAYER_${name})
        set(layer_registry "${layer_registry}#if NCNN_STRING\n{\"${class}\", ${class}_layer_creator},\n#else\n{${class}_layer_creator},\n#endif\n")
    else()
        set(layer_registry "${layer_registry}#if NCNN_STRING\n{\"${class}\", 0},\n#else\n{0},\n#endif\n")
    endif()

    if(WITH_LAYER_${name}_${NCNN_TARGET_ARCH})
        set(layer_registry_arch "${layer_registry_arch}#if NCNN_STRING\n{\"${class}\", ${class}_${NCNN_TARGET_ARCH}_layer_creator},\n#else\n{${class}_${NCNN_TARGET_ARCH}_layer_creator},\n#endif\n")
    else()
        set(layer_registry_arch "${layer_registry_arch}#if NCNN_STRING\n{\"${class}\", 0},\n#else\n{0},\n#endif\n")
    endif()

    if(WITH_LAYER_${name}_vulkan)
        set(layer_registry_vulkan "${layer_registry_vulkan}#if NCNN_STRING\n{\"${class}\", ${class}_vulkan_layer_creator},\n#else\n{${class}_vulkan_layer_creator},\n#endif\n")
    else()
        set(layer_registry_vulkan "${layer_registry_vulkan}#if NCNN_STRING\n{\"${class}\", 0},\n#else\n{0},\n#endif\n")
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "x86")
        if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512)
                ncnn_add_arch_opt_layer(${class} avx512 "/arch:AVX512 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_FMA)
                ncnn_add_arch_opt_layer(${class} fma "/arch:AVX /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX)
                ncnn_add_arch_opt_layer(${class} avx "/arch:AVX /D__SSSE3__ /D__SSE4_1__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512VNNI)
                ncnn_add_arch_opt_source(${class} avx512vnni "/arch:AVX512 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512VNNI__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512BF16)
                ncnn_add_arch_opt_source(${class} avx512bf16 "/arch:AVX512 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512BF16__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512FP16)
                ncnn_add_arch_opt_source(${class} avx512fp16 "/arch:AVX512 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512FP16__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVXVNNI)
                ncnn_add_arch_opt_source(${class} avxvnni "/arch:AVX2 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVXVNNI__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX2)
                ncnn_add_arch_opt_source(${class} avx2 "/arch:AVX2 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_XOP)
                ncnn_add_arch_opt_source(${class} xop "/arch:AVX /D__SSSE3__ /D__SSE4_1__ /D__XOP__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_F16C)
                ncnn_add_arch_opt_source(${class} f16c "/arch:AVX /D__SSSE3__ /D__SSE4_1__ /D__F16C__")
            endif()
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC" AND CMAKE_CXX_COMPILER_FRONTEND_VARIANT MATCHES "MSVC")
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512)
                ncnn_add_arch_opt_layer(${class} avx512 "/arch:AVX512 -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_FMA)
                ncnn_add_arch_opt_layer(${class} fma "/arch:AVX -mfma -mf16c /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX)
                ncnn_add_arch_opt_layer(${class} avx "/arch:AVX /D__SSSE3__ /D__SSE4_1__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512VNNI)
                ncnn_add_arch_opt_source(${class} avx512vnni "/arch:AVX512 -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512vnni /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512VNNI__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512BF16)
                ncnn_add_arch_opt_source(${class} avx512bf16 "/arch:AVX512 -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512bf16 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512BF16__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512FP16)
                ncnn_add_arch_opt_source(${class} avx512fp16 "/arch:AVX512 -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512fp16 /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVX512FP16__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVXVNNI)
                ncnn_add_arch_opt_source(${class} avxvnni "/arch:AVX2 -mfma -mf16c -mavxvnni /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__ /D__AVXVNNI__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX2)
                ncnn_add_arch_opt_source(${class} avx2 "/arch:AVX2 -mfma -mf16c /D__SSSE3__ /D__SSE4_1__ /D__FMA__ /D__F16C__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_XOP)
                ncnn_add_arch_opt_source(${class} xop "/arch:AVX -mxop /D__SSSE3__ /D__SSE4_1__ /D__XOP__")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_F16C)
                ncnn_add_arch_opt_source(${class} f16c "/arch:AVX -mf16c /D__SSSE3__ /D__SSE4_1__ /D__F16C__")
            endif()
        else()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512)
                ncnn_add_arch_opt_layer(${class} avx512 "-mavx512f -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_FMA)
                ncnn_add_arch_opt_layer(${class} fma "-mavx -mfma -mf16c")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX)
                ncnn_add_arch_opt_layer(${class} avx "-mavx")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512VNNI)
                ncnn_add_arch_opt_source(${class} avx512vnni "-mavx512f -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512vnni")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512BF16)
                ncnn_add_arch_opt_source(${class} avx512bf16 "-mavx512f -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512bf16")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX512FP16)
                ncnn_add_arch_opt_source(${class} avx512fp16 "-mavx512f -mavx512cd -mavx512bw -mavx512dq -mavx512vl -mfma -mf16c -mavx512fp16")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVXVNNI)
                ncnn_add_arch_opt_source(${class} avxvnni "-mavx2 -mfma -mf16c -mavxvnni")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_AVX2)
                ncnn_add_arch_opt_source(${class} avx2 "-mavx2 -mfma -mf16c")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_XOP)
                ncnn_add_arch_opt_source(${class} xop "-mavx -mxop")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_F16C)
                ncnn_add_arch_opt_source(${class} f16c "-mavx -mf16c")
            endif()
        endif()
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "arm" AND (CMAKE_SIZEOF_VOID_P EQUAL 4 AND NOT NCNN_TARGET_ILP32))
        if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC" OR (CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC" AND CMAKE_CXX_COMPILER_FRONTEND_VARIANT MATCHES "MSVC"))
            if(NCNN_VFPV4)
                ncnn_add_arch_opt_source(${class} vfpv4 "/arch:VFPv4 /D__ARM_FP=0x0E")
            endif()
        else()
            if(NCNN_VFPV4)
                if(NCNN_COMPILER_SUPPORT_ARM_VFPV4)
                    ncnn_add_arch_opt_source(${class} vfpv4 "-mfpu=neon-vfpv4")
                elseif(NCNN_COMPILER_SUPPORT_ARM_VFPV4_FP16)
                    ncnn_add_arch_opt_source(${class} vfpv4 "-mfpu=neon-vfpv4 -mfp16-format=ieee")
                endif()
            endif()
        endif()
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "arm" AND (CMAKE_SIZEOF_VOID_P EQUAL 8 OR NCNN_TARGET_ILP32))
        if(CMAKE_CXX_COMPILER_ID MATCHES "MSVC")
            if(NCNN_VFPV4)
                ncnn_add_arch_opt_source(${class} vfpv4 " ")
            endif()
            if(NCNN_ARM82)
                ncnn_add_arch_opt_source(${class} asimdhp "/arch:armv8.2 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82DOT)
                ncnn_add_arch_opt_source(${class} asimddp "/arch:armv8.2 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82FP16FML)
                ncnn_add_arch_opt_source(${class} asimdfhm "/arch:armv8.2 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_FP16_FML")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84BF16)
                ncnn_add_arch_opt_source(${class} bf16 "/arch:armv8.4 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD /D__ARM_FEATURE_FP16_FML /D__ARM_FEATURE_BF16_VECTOR_ARITHMETIC")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84I8MM)
                ncnn_add_arch_opt_source(${class} i8mm "/arch:armv8.4 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD /D__ARM_FEATURE_FP16_FML /D__ARM_FEATURE_MATMUL_INT8")
            endif()
            # TODO add support for sve family
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE2)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEBF16)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEI8MM)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEF32MM)
            endif()
        elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND CMAKE_CXX_SIMULATE_ID MATCHES "MSVC" AND CMAKE_CXX_COMPILER_FRONTEND_VARIANT MATCHES "MSVC")
            if(NCNN_VFPV4)
                ncnn_add_arch_opt_source(${class} vfpv4 " ")
            endif()
            if(NCNN_ARM82)
                ncnn_add_arch_opt_source(${class} asimdhp "/arch:armv8.2 -march=armv8.2-a+fp16 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82DOT)
                ncnn_add_arch_opt_source(${class} asimddp "/arch:armv8.2 -march=armv8.2-a+fp16+dotprod /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82FP16FML)
                ncnn_add_arch_opt_source(${class} asimdfhm "/arch:armv8.2 -march=armv8.2-a+fp16+fp16fml /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_FP16_FML")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84BF16)
                ncnn_add_arch_opt_source(${class} bf16 "/arch:armv8.4 -march=armv8.4-a+fp16+dotprod+bf16 /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD /D__ARM_FEATURE_FP16_FML /D__ARM_FEATURE_BF16_VECTOR_ARITHMETIC")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84I8MM)
                ncnn_add_arch_opt_source(${class} i8mm "/arch:armv8.4 -march=armv8.4-a+fp16+dotprod+i8mm /D__ARM_FEATURE_FP16_VECTOR_ARITHMETIC /D__ARM_FEATURE_DOTPROD /D__ARM_FEATURE_FP16_FML /D__ARM_FEATURE_MATMUL_INT8")
            endif()
            # TODO add support for sve family
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE2)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEBF16)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEI8MM)
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEF32MM)
            endif()
        else()
            if(NCNN_VFPV4)
                ncnn_add_arch_opt_source(${class} vfpv4 " ")
            endif()
            if(NCNN_ARM82)
                ncnn_add_arch_opt_source(${class} asimdhp "-march=armv8.2-a+fp16")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82DOT)
                ncnn_add_arch_opt_source(${class} asimddp "-march=armv8.2-a+fp16+dotprod")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM82FP16FML)
                ncnn_add_arch_opt_source(${class} asimdfhm "-march=armv8.2-a+fp16+fp16fml")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84BF16)
                ncnn_add_arch_opt_source(${class} bf16 "-march=armv8.4-a+fp16+dotprod+bf16")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM84I8MM)
                ncnn_add_arch_opt_source(${class} i8mm "-march=armv8.4-a+fp16+dotprod+i8mm")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE)
                ncnn_add_arch_opt_source(${class} sve "-march=armv8.6-a+fp16+dotprod+sve")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVE2)
                ncnn_add_arch_opt_source(${class} sve2 "-march=armv8.6-a+fp16+dotprod+sve2")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEBF16)
                ncnn_add_arch_opt_source(${class} svebf16 "-march=armv8.6-a+fp16+dotprod+sve+bf16")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEI8MM)
                ncnn_add_arch_opt_source(${class} svei8mm "-march=armv8.6-a+fp16+dotprod+sve+i8mm")
            endif()
            if(NCNN_RUNTIME_CPU AND NCNN_ARM86SVEF32MM)
                ncnn_add_arch_opt_source(${class} svef32mm "-march=armv8.6-a+fp16+dotprod+sve+f32mm")
            endif()
        endif()
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "mips")
        if(NCNN_RUNTIME_CPU AND NCNN_MSA)
            ncnn_add_arch_opt_layer(${class} msa "-mmsa")
        endif()
        if(NCNN_MMI)
            ncnn_add_arch_opt_source(${class} mmi "-mloongson-mmi")
        endif()
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "loongarch")
        if(NCNN_RUNTIME_CPU AND NCNN_LASX)
            ncnn_add_arch_opt_layer(${class} lasx "-mlasx -mlsx")
        endif()
        if(NCNN_RUNTIME_CPU AND NCNN_LSX)
            ncnn_add_arch_opt_layer(${class} lsx "-mlsx")
        endif()
    endif()

    if(NCNN_TARGET_ARCH STREQUAL "riscv" AND CMAKE_SIZEOF_VOID_P EQUAL 8)
        if(NCNN_RUNTIME_CPU AND NCNN_RVV)
            if(NCNN_COMPILER_SUPPORT_RVV_ZFH)
                ncnn_add_arch_opt_layer(${class} rvv "-march=rv64gcv_zfh")
            elseif(NCNN_COMPILER_SUPPORT_RVV_ZVFH)
                ncnn_add_arch_opt_layer(${class} rvv "-march=rv64gcv_zfh_zvfh0p1 -menable-experimental-extensions -D__fp16=_Float16")
            elseif(NCNN_COMPILER_SUPPORT_RVV)
                ncnn_add_arch_opt_layer(${class} rvv "-march=rv64gcv")
            endif()
        endif()
    endif()

    # generate layer_type_enum file
    set(layer_type_enum "${layer_type_enum}${class} = ${__LAYER_TYPE_ENUM_INDEX},\n")
    math(EXPR __LAYER_TYPE_ENUM_INDEX "${__LAYER_TYPE_ENUM_INDEX}+1")
endmacro()
