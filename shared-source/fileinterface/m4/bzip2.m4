# ===========================================================================
# Derived from: http://www.gnu.org/software/autoconf-archive/ax_check_zlib.html
# ===========================================================================
#
# SYNOPSIS
#
#   AX_CHECK_BZIP2([action-if-found], [action-if-not-found])
#
# DESCRIPTION
#
#   This macro searches for an installed bzip2 library. If nothing was
#   specified when calling configure, it searches first in /usr/local and
#   then in /usr, /opt/local and /sw. If the --with-bzip2=DIR is specified,
#   it will try to find it in DIR/include/bzlib.h and DIR/lib/libbz2.a. If
#   --without-bzip2 is specified, the library is not searched at all.
#
#   If either the header file (bzlib.h) or the library (libbz2) is not found,
#   shell commands 'action-if-not-found' is run. If 'action-if-not-found' is
#   not specified, the configuration exits on error, asking for a valid bzip2
#   installation directory or --without-bzip2.
#
#   If both header file and library are found, shell commands
#   'action-if-found' is run. If 'action-if-found' is not specified, the
#   default action appends '-I${ZLIB_HOME}/include' to CPFLAGS, appends
#   '-L$ZLIB_HOME}/lib' to LDFLAGS, prepends '-lz' to LIBS, and calls
#   AC_DEFINE(HAVE_LIBBZ2). You should use autoheader to include a definition
#   for this symbol in a config.h file. Sample usage in a C/C++ source is as
#   follows:
#
#     #ifdef HAVE_LIBBZ2
#     #include <bzlib.h>
#     #endif /* HAVE_LIBBZ2 */
#
# LICENSE
#
#   Copyright (c) 2008 Loic Dachary <loic@senga.org>
#   Copyright (c) 2010 Bastien Chevreux <bach@chevreux.org>
#   Copyright (c) 2014 Cameron Palmer <cdp2130@columbia.edu>
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2 of the License, or (at your
#   option) any later version.
#
#   This program is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
#   Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program. If not, see <http://www.gnu.org/licenses/>.
#
#   As a special exception, the respective Autoconf Macro's copyright owner
#   gives unlimited permission to copy, distribute and modify the configure
#   scripts that are the output of Autoconf when processing the Macro. You
#   need not follow the terms of the GNU General Public License when using
#   or distributing such scripts, even though portions of the text of the
#   Macro appear in them. The GNU General Public License (GPL) does govern
#   all other use of the material that constitutes the Autoconf Macro.
#
#   This special exception to the GPL applies to versions of the Autoconf
#   Macro released by the Autoconf Archive. When you make and distribute a
#   modified version of the Autoconf Macro, you may extend this special
#   exception to the GPL to apply to your modified version as well.

#serial 14

AU_ALIAS([CHECK_BZIP2], [AX_CHECK_BZIP2])
AC_DEFUN([AX_CHECK_BZIP2],
#
# Handle user hints
#
[AC_MSG_CHECKING(if bzip2 is wanted)
bzip2_places="/usr/local /usr /opt/local /sw"
AC_ARG_WITH([bzip2],
[  --with-bzip2=DIR       root directory path of bzip2 installation @<:@defaults to
                          /usr/local or /usr if not found in /usr/local@:>@
  --without-bzip2          to disable bzip2 usage completely],
[if test "$withval" != no ; then
  AC_MSG_RESULT(yes)
  if test -d "$withval"
  then
    bzip2_places="$withval $bzip2_places"
  else
    AC_MSG_WARN([Sorry, $withval does not exist, checking usual places])
  fi
else
  zlib_places=
  AC_MSG_RESULT(no)
fi],
[AC_MSG_RESULT(yes)])

#
# Locate bzip2, if wanted
#
if test -n "${bzip2_places}"
then
	# check the user supplied or any other more or less 'standard' place:
	#   Most UNIX systems      : /usr/local and /usr
	#   MacPorts / Fink on OSX : /opt/local respectively /sw
	for BZIP2_HOME in ${bzip2_places} ; do
	  if test -f "${BZIP2_HOME}/include/bzlib.h"; then break; fi
	    BZIP2_HOME=""
	    done

  BZIP2_OLD_LDFLAGS=$LDFLAGS
  BZIP2_OLD_CPPFLAGS=$CPPFLAGS
  if test -n "${BZIP2_HOME}"; then
        LDFLAGS="$LDFLAGS -L${BZIP2_HOME}/lib"
        CPPFLAGS="$CPPFLAGS -I${BZIP2_HOME}/include"
  fi
  AC_LANG_SAVE
  AC_LANG_C
  AC_CHECK_LIB([bz2], [BZ2_bzReadOpen], [bzip2_cv_bz2=yes], [bzip2_cv_bz2=no])
  AC_CHECK_HEADER([bzlib.h], [bzip2_cv_bzlib_h=yes], [bzip2_cv_bzlib_h=no])
  AC_LANG_RESTORE
  if test "$bzip2_cv_bz2" = "yes" && test "$bzip2_cv_bzlib_h" = "yes"
  then
    #
    # If both library and header were found, action-if-found
    #
    m4_ifblank([$1],[
                CPPFLAGS="$CPPFLAGS -I${BZIP2_HOME}/include"
                LDFLAGS="$LDFLAGS -L${BZIP2_HOME}/lib"
                LIBS="-lbz2 $LIBS"
                AC_DEFINE([HAVE_LIBBZ2], [1],
                          [Define to 1 if you have `bz2' library (-lbz2)])
               ],[
                # Restore variables
                LDFLAGS="$BZIP2_OLD_LDFLAGS"
                CPPFLAGS="$BZIP2_OLD_CPPFLAGS"
                $1
               ])
  else
    #
    # If either header or library was not found, action-if-not-found
    #
    m4_default([$2],[
                AC_MSG_ERROR([either specify a valid bzip2 installation with --with-bzip2=DIR or disable bzip2 usage with --without-bzip2])
                ])
  fi
fi
])
