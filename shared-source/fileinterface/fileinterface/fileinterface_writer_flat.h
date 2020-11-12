/*!
  \file fileinterface_writer_flat.h
  \brief standardized interface for uncompressed file output
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_FLAT_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_FLAT_H_

#include <fstream>
#include <stdexcept>
#include <string>

#include "fileinterface/fileinterface_writer_parent.h"

namespace fileinterface {
/*!
  \class fileinterface_writer_flat
  \brief for compatibility, interface for uncompressed files using ofstreams
 */
class fileinterface_writer_flat : public fileinterface_writer {
 public:
  /*!
    \brief constructor
   */
  fileinterface_writer_flat() : fileinterface_writer() {}
  /*!
    \brief destructor
   */
  ~fileinterface_writer_flat() throw() { close(); }
  /*!
    \brief open a file
    @param filename file to open
    \warning will destroy any existing file with the same name
   */
  void open(const char *filename);
  /*!
    \brief close the file
   */
  void close() {
    _output.close();
    clear();
  }
  /*!
    \brief clear internal state flags
  */
  void clear() { _output.clear(); }
  /*!
    \brief test whether the file is currently open
    \return whether the file is currently open
   */
  bool is_open() const { return _output.is_open(); }
  /*!
    \brief write a single character to output
    @param c character to write to output
   */
  void put(char c) { _output.put(c); }
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
  bool eof() const { return _output.eof(); }
  /*!
    \brief test whether connection is currently valid
    \return whether connection is currently valid
   */
  bool good() const { return _output.good(); }
  /*!
    \brief test whether a write operation has failed for this stream
    \return whether a write operation has failed for this stream
   */
  bool fail() const { return _output.fail(); }
  /*!
    \brief test whether connection is currently invalid
    \return whether connection is currently invalid
   */
  bool bad() const { return _output.bad(); }

 private:
  std::ofstream _output;  //!< file stream that actually does all the work
};
}  // namespace fileinterface

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_WRITER_FLAT_H_
