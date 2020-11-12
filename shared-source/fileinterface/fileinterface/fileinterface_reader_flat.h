/*!
  \file fileinterface_reader_flat.h
  \brief standardized interface for uncompressed file input
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_FLAT_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_FLAT_H_

#include <fstream>
#include <stdexcept>
#include <string>

#include "fileinterface/fileinterface_reader_parent.h"

namespace fileinterface {
/*!
  \class fileinterface_reader_flat
  \brief for compatibility, interface for uncompressed files using ifstreams
 */
class fileinterface_reader_flat : public fileinterface_reader {
 public:
  /*!
    \brief constructor
   */
  fileinterface_reader_flat() : fileinterface_reader() {}
  /*!
    \brief destructor
   */
  ~fileinterface_reader_flat() throw() {}
  /*!
    \brief open a file
    @param filename name of file to open
   */
  void open(const char *filename);
  /*!
    \brief close the file
   */
  void close() {
    _input.close();
    clear();
  }
  /*!
    \brief clear internal state flags
   */
  void clear() { _input.clear(); }
  /*!
    \brief test whether a file is currently open
    \return whether a file is currently open
   */
  bool is_open() const { return _input.is_open(); }
  /*!
    \brief get a single character from file
    \return the next single character from file
   */
  char get() { return _input.get(); }
  /*!
    \brief read a newline-delimited line from file
    @param s where the read line will be stored
    \return whether the line read operation was successful
   */
  bool getline(std::string *s);
  /*!
    \brief determine whether the stream is at the end of the file
    \return whether the stream is at the end of the file
   */
  bool eof() const { return _input.eof(); }
  /*!
    \brief determine whether the stream is in a valid state
    \return whether the stream is in a valid state
   */
  bool good() const { return _input.good(); }
  /*!
    \brief determine whether the stream is in an invalid state
    \return whether the stream is in an invalid state
   */
  bool bad() const { return _input.bad(); }
  /*!
    \brief read a specified number of characters from file
    @param buf allocated array of characters to which to write result
    @param n number of characters to attempt to read
   */
  void read(char *buf, std::streamsize n);

 private:
  std::ifstream _input; /*!< file stream that actually does all the work */
};
}  // namespace fileinterface

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_READER_FLAT_H_
