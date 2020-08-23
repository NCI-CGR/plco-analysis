/*!
  \file fileinterface_reader_gzip.cc
  \brief implementations for fileinterface zlib (gzip) file input
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

#include "fileinterface/fileinterface_reader_gzip.h"

#ifdef FILEINTERFACE_HAVE_LIBZ

imputation_comparison::fileinterface_reader_gzip::fileinterface_reader_gzip()
  : imputation_comparison::fileinterface_reader(),
    _gz_input(0),
    _eof(false),
    _buf(0),
    _buf_max(10000) {
  _buf = new char[_buf_max + 1];
  for (unsigned i = 0; i < _buf_max + 1; ++i)
    _buf[i] = '\0';
}

void imputation_comparison::fileinterface_reader_gzip::open(const char *filename) {
  if (!_gz_input) {
    _gz_input = gzopen(filename, "rb");
    if (!_gz_input)
      throw std::domain_error("imputation_comparison::fileinterface_reader_gzip::open: could not "
			      "open file \"" + std::string(filename) + "\"");
  } else
    throw std::domain_error("imputation_comparison::fileinterface_reader_gzip::open: reopen attempted "
			    "on active handle");
}

void imputation_comparison::fileinterface_reader_gzip::close() {
  if (_gz_input) {
    gzclose(_gz_input);
    _gz_input = 0;
  }
  clear();
}

void imputation_comparison::fileinterface_reader_gzip::clear() {
  _good = true;
  _bad = _fail = _eof = false;
}

bool imputation_comparison::fileinterface_reader_gzip::is_open() const {
  return _gz_input;
}

char imputation_comparison::fileinterface_reader_gzip::get() {
  read(_buf, 1);
  return _buf[0];
}

bool imputation_comparison::fileinterface_reader_gzip::getline(std::string &line) {
  line = "";
  while (true) {
    if (gzgets(_gz_input, _buf, _buf_max) == Z_NULL) {
      _eof = true;
      return line.size() > 0;
    }
    line += std::string(_buf);
    if (*line.rbegin() == '\n') {
      line = line.substr(0, line.size()-1);
      return true;
    }
  }
}

void imputation_comparison::fileinterface_reader_gzip::read(char *buf, std::streamsize n) {
  int my_errno = 0;
  if ((my_errno = gzread(_gz_input, reinterpret_cast<void *>(buf), n)) < 0) {
    throw std::domain_error("imputation_comparison::fileinterface_reader_gzip::read: read call of"
			    " size " + fi_to_string<std::streamsize>(n)
			    + " failed");
  } else if (!my_errno) {
    _eof = true;
  }
}

#endif //HAVE_LIBZ
