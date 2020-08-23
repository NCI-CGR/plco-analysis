/*!
  \file fileinterface_writer_bzip2.cc
  \brief method implementations for fileinterface bzip2 writer
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

#include "fileinterface/fileinterface_writer_bzip2.h"

#ifdef FILEINTERFACE_HAVE_LIBBZ2

void imputation_comparison::fileinterface_writer_bzip2::open(const char *filename) {
  if (_raw_output)
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2: attempted to reopen "
			    "in-use handle");
  _raw_output = fopen(filename, "w");
  if (!_raw_output)
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2: cannot open file \""
			    + std::string(filename) + "\"");
  int error = 0;
  _bz_output = BZ2_bzWriteOpen(&error, _raw_output, 9, 0, 0);
  if (error == BZ_CONFIG_ERROR) {
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2::open: bzip2 writing "
			    "library reports it was compiled improperly");
  } else if (error == BZ_PARAM_ERROR) {
    _fail = true;
  } else if (error != BZ_OK) {
    _bad = true;
  }
}

void imputation_comparison::fileinterface_writer_bzip2::close() {
  int error = 0;
  if (_bz_output) {
    BZ2_bzWriteClose(&error, _bz_output, 0, 0, 0);
    if (error == BZ_SEQUENCE_ERROR) {
      throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2::close: bzip reports "
			      "write/close operation called on read handle");
    }
    _bz_output = 0;
  }
  if (_raw_output) {
    fclose(_raw_output);
    _raw_output = 0;
  }
}

void imputation_comparison::fileinterface_writer_bzip2::clear() {
  _good = true;
  _bad = _fail = false;
}

bool imputation_comparison::fileinterface_writer_bzip2::is_open() const {
  return (_raw_output && _bz_output);
}

void imputation_comparison::fileinterface_writer_bzip2::put(char c) {
  int error = 0;
  BZ2_bzWrite(&error, _bz_output, reinterpret_cast<void *>(&c), 1);
  if (error == BZ_PARAM_ERROR ||
      error == BZ_IO_ERROR) {
    _fail = true;
  } else if (error == BZ_SEQUENCE_ERROR) {
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2::put: bzip reports "
			    "write operation called on read handle");
  }
}

void imputation_comparison::fileinterface_writer_bzip2::writeline(const std::string &orig_line) {
  int error = 0;
  std::string line = orig_line + get_newline();
  BZ2_bzWrite(&error, _bz_output, const_cast<void *>(reinterpret_cast<const void *>(line.c_str())), static_cast<int>(line.size()));
  if (error == BZ_PARAM_ERROR ||
      error == BZ_IO_ERROR) {
    _fail = true;
  } else if (error == BZ_SEQUENCE_ERROR) {
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2::writeline: bzip reports "
			    "write operation called on read handle");
  }
}

void imputation_comparison::fileinterface_writer_bzip2::write(char *buf, std::streamsize n) {
  int error = 0;
  BZ2_bzWrite(&error, _bz_output, reinterpret_cast<void *>(buf), static_cast<int>(n));
  if (error == BZ_PARAM_ERROR ||
      error == BZ_IO_ERROR) {
    _fail = true;
  } else if (error == BZ_SEQUENCE_ERROR) {
    throw std::domain_error("imputation_comparison::fileinterface_writer_bzip2::write: bzip reports "
			    "write operation called on read handle");
  }
}

#endif //HAVE_LIBBZ2
