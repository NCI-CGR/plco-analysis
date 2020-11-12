/*!
  \file fileinterface_reader_gzip.cc
  \brief implementations for fileinterface zlib (gzip) file input
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer
 */

#include "fileinterface/fileinterface_reader_gzip.h"

#ifdef FILEINTERFACE_HAVE_LIBZ

fileinterface::fileinterface_reader_gzip::fileinterface_reader_gzip()
    : fileinterface::fileinterface_reader(),
      _gz_input(0),
      _eof(false),
      _buf(0),
      _buf_max(10000) {
  _buf = new char[_buf_max + 1];
  for (unsigned i = 0; i < _buf_max + 1; ++i) _buf[i] = '\0';
}

void fileinterface::fileinterface_reader_gzip::open(const char *filename) {
  if (!_gz_input) {
    _gz_input = gzopen(filename, "rb");
    if (!_gz_input)
      throw std::domain_error(
          "fileinterface::fileinterface_reader_gzip::open: could not "
          "open file \"" +
          std::string(filename) + "\"");
  } else {
    throw std::domain_error(
        "fileinterface::fileinterface_reader_gzip::open: reopen "
        "attempted "
        "on active handle");
  }
}

void fileinterface::fileinterface_reader_gzip::close() {
  if (_gz_input) {
    gzclose(_gz_input);
    _gz_input = 0;
  }
  clear();
}

void fileinterface::fileinterface_reader_gzip::clear() {
  _good = true;
  _bad = _fail = _eof = false;
}

bool fileinterface::fileinterface_reader_gzip::is_open() const {
  return _gz_input;
}

char fileinterface::fileinterface_reader_gzip::get() {
  read(_buf, 1);
  return _buf[0];
}

bool fileinterface::fileinterface_reader_gzip::getline(std::string *line) {
  if (!line) throw std::domain_error("gzip::getline: called with null pointer");
  *line = "";
  while (true) {
    if (gzgets(_gz_input, _buf, _buf_max) == Z_NULL) {
      _eof = true;
      return line->size() > 0;
    }
    *line += std::string(_buf);
    if (*line->rbegin() == '\n') {
      *line = line->substr(0, line->size() - 1);
      return true;
    }
  }
}

void fileinterface::fileinterface_reader_gzip::read(char *buf,
                                                    std::streamsize n) {
  int my_errno = 0;
  if ((my_errno = gzread(_gz_input, reinterpret_cast<void *>(buf), n)) < 0) {
    throw std::domain_error(
        "fileinterface::fileinterface_reader_gzip::read: read call of"
        " size " +
        fi_to_string<std::streamsize>(n) + " failed");
  } else if (!my_errno) {
    _eof = true;
  }
}

#endif  // HAVE_LIBZ
