/*!
  \file fileinterface_writer_parent.h
  \brief virtual shared writer class declarations
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

#ifndef __imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_PARENT_H__
#define __imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_PARENT_H__

#include <string>
#include <ios>

#include "fileinterface/helper.h"

namespace imputation_comparison {
  /*!
    \class fileinterface_writer
    \brief parent class for all fileinterface writers
   */
  class fileinterface_writer {
  public:
    /*!
      \brief constructor
     */
    fileinterface_writer()
      : _good(true), _bad(false), _fail(false) {}
    /*!
      \brief virtual destructor
     */
    virtual ~fileinterface_writer() throw() {}
    /*!
      \brief open a file, converting name from string to char*
      @param filename name of file to open
     */
    void open(const std::string &filename) {open(filename.c_str());}
    /*!
      \brief virtual file open
      @param filename of file to open
     */
    virtual void open(const char *filename) = 0;
    /*!
      \brief virtual file close
     */
    virtual void close() = 0;
    /*!
      \brief virtual clear state flags
     */
    virtual void clear() = 0;
    /*!
      \brief virtual test if file is currently open
      \return whether file is currently open
     */
    virtual bool is_open() const = 0;
    /*!
      \brief virtual write a single character to file
      @param c character to write to file
     */
    virtual void put(char c) = 0;
    /*!
      \brief virtual write a line to file, appending newline
      @param s line to write to file
     */
    virtual void writeline(const std::string &s) = 0;
    /*!
      \brief virtual write a specified number of characters to file
      @param buf array containing characters to write to file
      @param n how many characters in buffer to write to file
     */
    virtual void write(char *buf, std::streamsize n) = 0;
    /*!
      \brief virtual whether end of file has been reached
      \return whether end of file has been reached
     */
    virtual bool eof() const = 0;
    /*!
      \brief virtual test of whether stream is in valid state
      \return whether stream is in valid state
     */
    virtual bool good() const = 0;
    /*!
      \brief virtual test of whether write operation failed
      \return whether write operation failed
     */
    virtual bool fail() const = 0;
    /*!
      \brief virtual test of whether stream is in invalid state
      \return whether stream is in invalid state
     */
    virtual bool bad() const = 0;
  protected:
    bool _good; //!< internal state flag: whether stream is in valid state
    bool _bad; //!< internal state flag: whether stream is in invalid state
    bool _fail; //!< internal state flag: whether past write operation has failed
  };
}

#endif //__imputation_comparison_FILEINTERFACE_FILEINTERFACE_WRITER_PARENT_H__
