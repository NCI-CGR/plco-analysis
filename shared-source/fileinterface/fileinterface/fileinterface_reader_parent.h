/*!
  \file fileinterface_reader_parent.h
  \brief virtual shared reader class declarations
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

#ifndef __imputation_comparison_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H__
#define __imputation_comparison_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H__

#include <string>
#include <ios>

#include "fileinterface/helper.h"

namespace imputation_comparison {
  /*!
    \class fileinterface_reader
    \brief parent class for all fileinterface readers
   */
  class fileinterface_reader {
  public:
    /*!
      \brief constructor
    */
    fileinterface_reader() 
      : _good(true), _bad(false), _fail(false) {}
    /*!
      \brief virtual destructor
     */
    virtual ~fileinterface_reader() throw() {}
    /*!
      \brief open a file, converting name from string to char*
      @param filename name of file to open
     */
    void open(const std::string &filename) {open(filename.c_str());}
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
    virtual bool getline(std::string &s) = 0;
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
    bool _good; //!< internal state flag: whether stream is in valid state
    bool _bad; //!< internal state flag: whether stream is in invalid state
    bool _fail; //!< internal state flag: whether past read operation has failed
  };
}

#endif //__imputation_comparison_FILEINTERFACE_FILEINTERFACE_READER_PARENT_H__
