/*!
  \file fileinterface_reader_bzip2.cc
  \brief method implementations for bzip2 reader
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

#include "fileinterface/fileinterface_reader_bzip2.h"

#ifdef FILEINTERFACE_HAVE_LIBBZ2

imputation_comparison::fileinterface_reader_bzip2::fileinterface_reader_bzip2()
  : fileinterface_reader(),
    _raw_input(0),
    _bz_input(0),
    _eof(false),
    _buf(0),
    _buf_max(10000),
    _buf_read(0),
    _buf_remaining(0) {
  _buf = new char[_buf_max + 1];
  for (unsigned i = 0; i < _buf_max + 1; ++i)
    _buf[i] = '\0';
}

void imputation_comparison::fileinterface_reader_bzip2::open(const char *filename) {
  if (_raw_input)
    throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2: attempted to reopen "
			    "in-use handle");
  _raw_input = fopen(filename, "r");
  if (!_raw_input)
    throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2: cannot open file \""
			    + std::string(filename) + "\"");
  int error = 0;
  _bz_input = BZ2_bzReadOpen(&error, _raw_input, 0, 0, NULL, 0);
  if (error == BZ_CONFIG_ERROR) {
    throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2::open: bzip2 reading "
			    "library reports it was compiled improperly");
  } else if (error == BZ_PARAM_ERROR) {
    _fail = true;
  } else if (error != BZ_OK) {
    _bad = true;
  }
}

void imputation_comparison::fileinterface_reader_bzip2::close() {
  if (_bz_input) {
    int error = 0;
    BZ2_bzReadClose(&error, _bz_input);
    if (error == BZ_SEQUENCE_ERROR)
      throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2::close: bzip2 reports "
			      "read/close operation called on write handle");
    _bz_input = 0;
  }
  if (_raw_input) {
    fclose(_raw_input);
    _raw_input = 0;
  }
  clear();
}

void imputation_comparison::fileinterface_reader_bzip2::clear() {
  _good = true;
  _bad = _fail = false;
  _buf_remaining = _buf_read = 0;
}

bool imputation_comparison::fileinterface_reader_bzip2::is_open() const {
  return (_raw_input && _bz_input);
}

char imputation_comparison::fileinterface_reader_bzip2::get() {
  if (!_buf_remaining) {
    refresh_buffer();
  }
  if (!_buf_remaining)
    throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2::get: end of file");
  --_buf_remaining;
  return _buf[_buf_read - (_buf_remaining + 1)];
}

bool imputation_comparison::fileinterface_reader_bzip2::getline(std::string &res) {
  //std::string res = "";
  bool retval = false;
  res = "";
  std::string::size_type find_newline = 0, res_start = 0;
  if (_buf_remaining) {
    retval = true;
    res = std::string(_buf + (_buf_read - _buf_remaining));
    find_newline = res.find(get_newline());
    if (find_newline != std::string::npos) {
      res = res.substr(0, find_newline);
      _buf_remaining -= res.size() + get_newline().size();
      return retval;
    } else {
      _buf_remaining = 0;
    }
  }
  while (!eof() && good() && !bad() && !_fail) {
    res_start = res.size();
    refresh_buffer();
    if (_buf_remaining) {
      retval = true;
      res += std::string(_buf);
      find_newline = res.find(get_newline());
      if (find_newline != std::string::npos) {
	res = res.substr(0, find_newline);
	_buf_remaining -= res.size() - res_start + get_newline().size();
	return retval;
      } else {
	_buf_remaining = 0;
      }
    }
  }
  return (_fail || bad() ? false : retval);
}

bool imputation_comparison::fileinterface_reader_bzip2::eof() const {
  return _eof;
}

bool imputation_comparison::fileinterface_reader_bzip2::good() const {
  return _good;
}

bool imputation_comparison::fileinterface_reader_bzip2::bad() const {
  return _bad;
}

void imputation_comparison::fileinterface_reader_bzip2::read(char *target, std::streamsize n) {
  unsigned amount_read = 0;
  if (_buf_remaining) {
    for ( ; amount_read < _buf_remaining && amount_read < n; ++amount_read) {
      target[amount_read] = _buf[_buf_read - _buf_remaining];
    }
    _buf_remaining -= amount_read;
  }
  if (amount_read < n && !eof()) {
    //read the rest directly?
    int error = 0;
    BZ2_bzRead(&error, _bz_input, reinterpret_cast<void *>(target), n - amount_read);
    if (error == BZ_PARAM_ERROR ||
	error == BZ_IO_ERROR ||
	error == BZ_MEM_ERROR) {
      _fail = true;
    } else if (error == BZ_UNEXPECTED_EOF ||
	       error == BZ_DATA_ERROR ||
	       error == BZ_DATA_ERROR_MAGIC) {
      _bad = true;
    } else if (error == BZ_STREAM_END) {
      _eof = true;
      _fail = true;
    } else if (error == BZ_SEQUENCE_ERROR) {
      throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2::read: bzip2 reports "
			      "read called on stream opened as write");
    }
  } else if (eof()) {
    _fail = true;
  }
}

void imputation_comparison::fileinterface_reader_bzip2::refresh_buffer() {
  if (!eof()) {
    int error = 0;
    int num_read = BZ2_bzRead(&error, _bz_input, reinterpret_cast<void *>(_buf), _buf_max);
    if (error == BZ_PARAM_ERROR ||
	error == BZ_IO_ERROR ||
	error == BZ_MEM_ERROR) {
      _fail = true;
    } else if (error == BZ_UNEXPECTED_EOF ||
	       error == BZ_DATA_ERROR ||
	       error == BZ_DATA_ERROR_MAGIC) {
      _bad = true;
    } else if (error == BZ_STREAM_END) {
      _eof = true;
      _fail = true;
    } else if (error == BZ_SEQUENCE_ERROR) {
      throw std::domain_error("imputation_comparison::fileinterface_reader_bzip2::refresh_buffer: bzip2 reports "
			      "read called on stream opened as write");
    }
    _buf_remaining = _buf_read = static_cast<unsigned>(num_read);
    //if (num_read < _buf_max) {
    //_eof = _fail = true;
    //}
  } else _fail = true;
}

#endif //HAVE_LIBBZ2
