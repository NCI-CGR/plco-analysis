#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT(qsub_job_monitor, 1.0, palmercd@nih.gov)
AC_CONFIG_AUX_DIR([.])
AM_INIT_AUTOMAKE([-Wall -Werror subdir-objects])
AM_SILENT_RULES([no])
AM_PROG_AR
LT_INIT
AC_CONFIG_SRCDIR([qsub_job_monitor/main.cc])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([temp_config.h])
AX_PREFIX_CONFIG_H([qsub_job_monitor/config.h])

# Checks for programs.
AC_LANG([C++])
AC_PROG_CXX
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_CHECK_PROGS([INSTALL_INFO], [install-info])
AC_CHECK_PROGS([MAKEINFO], [makeinfo])
AC_CHECK_PROGS([TEXI2PDF], [texi2pdf])
AC_CHECK_PROGS([TEXI2DVI], [texi2dvi])
AC_PROG_CXX_C_O
AX_BOOST_BASE([1.71.0],[found the thing],[did not find the thing])
#AC_ARG_ENABLE([threads], [AS_HELP_STRING([--disable-threads],
#		       [disable hyperthreading support (default=no)])],
#		       [],
#		       [AX_PTHREAD])
#AS_IF([test "x$ac_disable_threads" != xyes],
#	    [AX_PTHREAD]) #([CFLAGS=$CFLAGS $PTHREAD_CFLAGS])
#fi

AX_CXX_COMPILE_STDCXX_17([noext], [mandatory])

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.

# Checks for library functions.

AC_CONFIG_FILES([
 Makefile
 qsub_job_monitor-1.0.pc
])
AC_OUTPUT
