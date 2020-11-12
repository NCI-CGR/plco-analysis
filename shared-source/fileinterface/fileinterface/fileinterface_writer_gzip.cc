/*!
  \file fileinterface_writer_gzip.cc
  \brief method implementations for fileinterface gzip writer
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

#include "fileinterface/fileinterface_writer_gzip.h"

#ifdef FILEINTERFACE_HAVE_LIBZ

void fileinterface::fileinterface_writer_gzip::open(const char *filename) {
  if (!_gz_output) {
    _gz_output = gzopen(filename, "wb");
    if (!_gz_output)
      throw std::domain_error(
          "fileinterface::fileinterface_writer_gzip::open: cannot open "
          "file \"" +
          std::string(filename) + "\"");
  } else {
    throw std::domain_error(
        "fileinterface::fileinterface_writer_gzip::open: reopen "
        "attempted with active handle");
  }
}

void fileinterface::fileinterface_writer_gzip::close() {
  if (_gz_output) {
    gzclose(_gz_output);
    _gz_output = 0;
  }
  clear();
}

void fileinterface::fileinterface_writer_gzip::clear() {
  _good = true;
  _bad = _fail = _eof = false;
}

bool fileinterface::fileinterface_writer_gzip::is_open() const {
  return _gz_output;
}

void fileinterface::fileinterface_writer_gzip::put(char c) { write(&c, 1); }

void fileinterface::fileinterface_writer_gzip::writeline(
    const std::string &linemod) {
  std::string line = linemod + get_newline();
  if (gzputs(_gz_output, line.c_str()) < 0)
    throw std::domain_error(
        "fileinterface::fileinterface_writer_gzip::writeline: write of "
        "line \"" +
        line + "\" failed");
}

void fileinterface::fileinterface_writer_gzip::write(char *buf,
                                                     std::streamsize n) {
  if (gzwrite(_gz_output, reinterpret_cast<void *>(buf), n) < 1) {
    throw std::domain_error(
        "fileinterface::fileinterface_writer_gzip::write: write call of"
        " size " +
        fi_to_string<std::streamsize>(n) + " failed");
  }
}

#endif  // FILEINTERFACE_HAVE_LIBZ
