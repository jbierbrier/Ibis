 macro(sourcefile_to_string SOURCE_FILE RESULT_CMAKE_VAR)
     file(STRINGS ${SOURCE_FILE} FileStrings)
     foreach(SourceLine ${FileStrings})
       # replace all \ with \\ to make the c string constant work
       string(REGEX REPLACE "\\\\" "\\\\\\\\" TempSourceLine "${SourceLine}")
       # replace all " with \" to make the c string constant work
       string(REGEX REPLACE "\"" "\\\\\"" EscapedSourceLine "${TempSourceLine}")
       set(${RESULT_CMAKE_VAR} "${${RESULT_CMAKE_VAR}}\n\"${EscapedSourceLine}\\n\"")
     endforeach(SourceLine)
  endmacro(sourcefile_to_string)

  macro(write_gpu_kernel_to_file OPENCL_FILE GPUFILTER_NAME GPUFILTER_KERNELNAME
     OUTPUT_FILE SRC_VAR)
    sourcefile_to_string(${OPENCL_FILE} ${GPUFILTER_KERNELNAME}_SourceString)
    set(${GPUFILTER_KERNELNAME}_KernelString
         "#include \"itk${GPUFILTER_NAME}.h\"\n\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}namespace itk\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}{\n\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}const char* ${GPUFILTER_KERNELNAME}::GetOpenCLSource()\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}{\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}  return ${${GPUFILTER_KERNELNAME}_SourceString};\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}}\n\n")
    set(${GPUFILTER_KERNELNAME}_KernelString
        "${${GPUFILTER_KERNELNAME}_KernelString}}\n")

    file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}
         "${${GPUFILTER_KERNELNAME}_KernelString}")

    add_custom_target(${GPUFILTER_KERNELNAME}_Target
                      SOURCES ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE})
    add_dependencies(${GPUFILTER_KERNELNAME}_Target ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE})
    add_dependencies(${GPUFILTER_KERNELNAME}_Target ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt)
    configure_file(${OPENCL_FILE}
                   ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}.cl COPYONLY)
    add_dependencies(${GPUFILTER_KERNELNAME}_Target ${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}.cl)
    set_source_files_properties(${CMAKE_CURRENT_BINARY_DIR}/${OUTPUT_FILE}
                                PROPERTIES GENERATED ON)
    set(${SRC_VAR} ${${SRC_VAR}} ${OUTPUT_FILE})
  endmacro(write_gpu_kernel_to_file)

  macro(write_gpu_kernels GPUKernels GPU_SRC)
    foreach(GPUKernel ${GPUKernels})
      get_filename_component(FilterName ${GPUKernel} NAME_WE)
      write_gpu_kernel_to_file(${GPUKernel} ${FilterName} ${FilterName}Kernel "${FilterName}Kernel.cxx" ${GPU_SRC})
    endforeach(GPUKernel)
  endmacro(write_gpu_kernels)