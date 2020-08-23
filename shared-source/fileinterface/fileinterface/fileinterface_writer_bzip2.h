/*!
  \file fileinterface_writer_bzip2.h
  \brief bzip2-specific writer class definitions
 */
/*
  Copyright 2016 Cameron Palmer

  This file is part of gwas-winners-curse.
  
  gwas-winners-curse is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.
  
  gwas-winners-curse is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with gwas-winners-curse.  If not, see <http://www.gnu.org/licenses/>.
*/

#ifndef __imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H__
#define __imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H__

#include "fileinterface/config.h"
#ifdef FILEINTERFACE_HAVE_LIBBZ2

#include "fileinterface/fileinterface_writer_parent.h"

#include <string>
#include <stdexcept>
#include <cstdlib>
#include <cstdio>
#include <bzlib.h>

namespace imputation_comparison {
  /*!
    \class fileinterface_writer_bzip2
    \brief interface for bzip2 file output that doesn't break my brain
   */
  class fileinterface_writer_bzip2 : public fileinterface_writer {
  public:
    /*!
      \brief constructor
     */
    fileinterface_writer_bzip2()
      : fileinterface_writer(),
      _raw_output(0), _bz_output(0) {}
    /*!
      \brief destructor
     */
    ~fileinterface_writer_bzip2() throw() {close();}
    /*!
      \brief open a file
      @param filename name of file to open
     */
    void open(const char *filename);
    /*!
      \brief close the file
     */
    void close();
    /*!
      \brief clear internal state flags
     */
    void clear();
    /*!
      \brief test whether the file is currently open
      \return whether the file is currently open
     */
    bool is_open() const;
    /*!
      \brief write a single character to file
      @param c character to write to file
     */
    void put(char c);
    /*!
      \brief write a line to file, appending a system-specific newline
      @param s line to write to file
     */
    void writeline(const std::string &s);
    /*!
      \brief write a specified number of characters to file
      @param buf character buffer containing contents to be written
      @param n number of characters from buffer to write to file
     */
    void write(char *buf, std::streamsize n);
    /*!
      \brief test whether end of file has been reached
      \return whether end of file has been reached
     */
    bool eof() const {return false;}
    /*!
      \brief test whether connection is currently valid
      \return whether connection is currently valid
     */
    bool good() const {return _good;}
    /*!
      \brief test whether a write operation has failed for this stream
      \return whether a write operation has failed for this stream
     */
    bool fail() const {return _fail;}
    /*!
      \brief test whether connection is currently invalid
      \return whether connection is currently invalid
     */
    bool bad() const {return _bad;}
  private:
    FILE *_raw_output; //!< C-style file handle used by bz2 library
    BZFILE *_bz_output; //!< bz2 library interface to underlying file pointer
  };
}


#endif //FILEINTERFACE_HAVE_LIBBZ2

#endif //__imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H__
