find_path(UNWIND_INCLUDE_DIR NAMES libunwind.h)
find_library(UNWIND_LIBRARY NAMES unwind System)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(UNWIND DEFAULT_MSG UNWIND_INCLUDE_DIR)
find_package_handle_standard_args(libunwind DEFAULT_MSG UNWIND_LIBRARY)
