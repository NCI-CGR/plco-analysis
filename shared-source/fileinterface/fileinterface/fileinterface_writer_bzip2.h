/*!
  \file fileinterface_writer_bzip2.h
  \brief bzip2-specific writer class definitions
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H_

#include "fileinterface/config.h"
#ifdef FILEINTERFACE_HAVE_LIBBZ2

#include <bzlib.h>

#include <cstdio>
#include <cstdlib>
#include <stdexcept>
#include <string>

#include "fileinterface/fileinterface_writer_parent.h"

namespace fileinterface {
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
      : fileinterface_writer(), _raw_output(0), _bz_output(0) {}
  /*!
    \brief destructor
   */
  ~fileinterface_writer_bzip2() throw() { close(); }
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
  bool eof() const { return false; }
  /*!
    \brief test whether connection is currently valid
    \return whether connection is currently valid
   */
  bool good() const { return _good; }
  /*!
    \brief test whether a write operation has failed for this stream
    \return whether a write operation has failed for this stream
   */
  bool fail() const { return _fail; }
  /*!
    \brief test whether connection is currently invalid
    \return whether connection is currently invalid
   */
  bool bad() const { return _bad; }

 private:
  FILE *_raw_output;   //!< C-style file handle used by bz2 library
  BZFILE *_bz_output;  //!< bz2 library interface to underlying file pointer
};
}  // namespace fileinterface

#endif  // FILEINTERFACE_HAVE_LIBBZ2

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_BZIP2_H_
