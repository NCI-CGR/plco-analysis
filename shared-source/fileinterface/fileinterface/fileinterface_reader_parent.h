/*!
  \file fileinterface_reader_parent.h
  \brief virtual shared reader class declarations
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H_

#include <ios>
#include <string>

#include "fileinterface/helper.h"

namespace fileinterface {
/*!
  \class fileinterface_reader
  \brief parent class for all fileinterface readers
 */
class fileinterface_reader {
 public:
  /*!
    \brief constructor
  */
  fileinterface_reader() : _good(true), _bad(false), _fail(false) {}
  /*!
    \brief virtual destructor
   */
  virtual ~fileinterface_reader() throw() {}
  /*!
    \brief open a file, converting name from string to char*
    @param filename name of file to open
   */
  void open(const std::string &filename) { open(filename.c_str()); }
  /*!
    \brief virtual file open
    @param filename name of file to open
   */
  virtual void open(const char *filename) = 0;
  /*!
    \brief virtual close a file
   */
  virtual void close() = 0;
  /*!
    \brief virtual clear internal state flags
   */
  virtual void clear() = 0;
  /*!
    \brief virtual test whether file is open
    \return whether file is open
   */
  virtual bool is_open() const = 0;
  /*!
    \brief virtual get a single character from file
    \return the next single character from file
   */
  virtual char get() = 0;
  /*!
    \brief virtual get a line from file
    @param s storage from line from file
    \return whether line read operation was successful
   */
  virtual bool getline(std::string *s) = 0;
  /*!
    \brief virtual test whether end of file was reached
    \return whether end of file was reached
   */
  virtual bool eof() const = 0;
  /*!
    \brief virtual test whether stream is in valid state
    \return whether stream is in valid state
   */
  virtual bool good() const = 0;
  /*!
    \brief virtual test whether stream is in invalid state
    \return whether stream is in invalid state
   */
  virtual bool bad() const = 0;
  /*!
    \brief virtual read a specified number of characters from file
    @param buf array storage for characters from file
    @param n number of characters to attempt to read
   */
  virtual void read(char *buf, std::streamsize n) = 0;

 protected:
  bool _good; /*!< internal state flag: whether stream is in valid state */
  bool _bad;  /*!< internal state flag: whether stream is in invalid state */
  bool
      _fail; /*!< internal state flag: whether past read operation has failed */
};
}  // namespace fileinterface

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H_
