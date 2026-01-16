cmake_minimum_required(VERSION 3.10.2)
project(skbuild_pycrtm)
enable_language(Fortran)

list( APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake )
find_package(F2PY REQUIRED)
find_package(PythonLibs REQUIRED)
find_package(Python3 REQUIRED COMPONENTS Development NumPy)
find_package( OpenMP COMPONENTS Fortran )
find_package( NetCDF REQUIRED COMPONENTS Fortran)
include_directories(${PYTHON_INCLUDE_DIRS})
include_directories(${_Python3_NumPy_INCLUDE_DIR})
include_directories(NetCDF_F90_INCLUDE_DIRS)
get_filename_component(CDF_LIB_PATH ${NetCDF_Fortran_LIBRARY} DIRECTORY)
find_package(Python REQUIRED COMPONENTS Interpreter Development.Module NumPy)

if (EXISTS $ENV{CRTM_INSTALL}/module/crtm/${CMAKE_Fortran_COMPILER_ID}/${CMAKE_Fortran_COMPILER_VERSION}/)
    set(crtm_INCLUDE $ENV{CRTM_INSTALL}/module/crtm/${CMAKE_Fortran_COMPILER_ID}/${CMAKE_Fortran_COMPILER_VERSION}/)
else()
    set(crtm_INCLUDE $ENV{CRTM_INSTALL}/include/)
endif()

if (EXISTS $ENV{CRTM_INSTALL}/lib64/)
    set(crtm_LIB $ENV{CRTM_INSTALL}/lib64/)
elseif(EXISTS $ENV{CRTM_INSTALL}/lib/)
    set(crtm_LIB $ENV{CRTM_INSTALL}/lib/)
else()
    set(crtm_LIB $ENV{CRTM_INSTALL})
endif()   

if ("${CMAKE_Fortran_COMPILER_ID}" MATCHES "Intel")
    set(ompFlag "-liomp5")
    set(switch_fun "intelem")
    set(preproc "-fpp")
else()
    set(ompFlag "-lgomp")
    set(switch_fun "gfortran")
    set(preproc "-cpp")
endif()
set(f2py_module_name "pycrtm_")
set(fortran_src_file "${CMAKE_CURRENT_SOURCE_DIR}/pycrtm.f90")
set(generated_module_file ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}${PYTHON_EXTENSION_MODULE_SUFFIX})
#_dumb is used to avoid circular dependency which breaks Ninja.
add_custom_target(${f2py_module_name}_dumb ALL
  DEPENDS ${generated_module_file}
  )
if (EXISTS $ENV{CRTM_INSTALL}/module/crtm/${CMAKE_Fortran_COMPILER_ID}/${CMAKE_Fortran_COMPILER_VERSION}/crtm_active_sensor.mod)
  set(preproc "${preproc} -DPYCRTM_ACTIVE")
  add_custom_command(
    OUTPUT ${generated_module_file}
    COMMAND python -m numpy.f2py
      -m ${f2py_module_name}
      -h ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}.pyf ${fortran_src_file}
    COMMAND python -m numpy.f2py
      --fcompiler=${switch_fun}
      --f90flags=${preproc} 
      -c
      ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}.pyf 
      ${fortran_src_file}
      -I${crtm_INCLUDE}
      -I${NETCDF_FORTRAN_INCLUDE_DIRS}
      -L${CDF_LIB_PATH}
      -L${crtm_LIB}
      -lcrtm
      -lnetcdff
      ${ompFlag}
# should work according to f2py documentation but doesn't. Have to set it through --f90flags as above.
#      -DPYCRTM_ACTIVE
      only: 
      wrap_forward 
      wrap_k_matrix
      wrap_forward_active
      wrap_k_matrix_active
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
else()
  add_custom_command(
    OUTPUT ${generated_module_file}
    COMMAND python -m numpy.f2py
      -m ${f2py_module_name}
      -h ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}.pyf ${fortran_src_file}
    COMMAND python -m numpy.f2py
      --fcompiler=${switch_fun}
      -c
      ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}.pyf 
      ${fortran_src_file}
      --f90flags=${preproc} 
      -I${crtm_INCLUDE}
      -I${NETCDF_FORTRAN_INCLUDE_DIRS}
      -L${CDF_LIB_PATH}
      -L${crtm_LIB}
      -lcrtm
      -lnetcdff
      ${ompFlag}
      only: 
      wrap_forward 
      wrap_k_matrix
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
endif()
#Shouldn't need this, but scikit-build won't grab the shared object otherwise.
list(GET _Python3_INTERPRETER_PROPERTIES 6 version)
set(produced_so ${CMAKE_CURRENT_BINARY_DIR}/${f2py_module_name}.${version}.so)
#Move to pycrtm directory
if (EXISTS ${crtm_LIB}/libcrtm.so)
    set(libcrtm_so ${crtm_LIB}/libcrtm.so)
endif()
if (EXISTS ${crtm_LIB}/libcrtm.dylib)
    set(libcrtm_so ${crtm_LIB}/libcrtm.dylib)
endif()


#Move to pycrtm directory
install(FILES ${produced_so} DESTINATION pycrtm_)
install(FILES ${libcrtm_so} DESTINATION pycrtm_)
#Move configuration into install 
install(FILES pycrtm_setup.txt DESTINATION pycrtm_)
