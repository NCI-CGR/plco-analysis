/*!
  \file plinkbed.cc
  \brief method implementations for fileinterface plink bedfile IO
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#include "fileinterface/plinkbed.h"

fileinterface::plinkbed_reader::plinkbed_reader(
    unsigned line_length, const std::string &compression_level)
    : fileinterface::fileinterface_reader(),
      _input(0),
      _buf(0),
      _line_length(line_length),
      _line_length_packed(0) {
  _compress = interpret_compression(compression_level);
  _line_length_packed = line_length / 4 + (line_length % 4 ? 1 : 0);
  _buf = new char[_line_length_packed];
}

void fileinterface::plinkbed_reader::open(const char *filename) {
  if (_input)
    throw std::domain_error(
        "fileinterface::plinkbed_reader::open: reopen attempted "
        "on active handle");
  if (_compress == GZIP) {
#ifdef FILEINTERFACE_HAVE_LIBZ
    _input = new fileinterface::fileinterface_reader_gzip;
#else
    throw std::domain_error("gzip compression requested for plinkbed read \"" +
                            std::string(filename) +
                            "\" but support for zlib not compiled");
#endif  // FILEINTERFACE_HAVE_LIBZ
  } else if (_compress == BZIP2) {
#ifdef FILEINTERFACE_HAVE_LIBBZ2
    _input = new fileinterface::fileinterface_reader_bzip2;
#else
    throw std::domain_error("bzip2 compression requested for plinkbed read \"" +
                            std::string(filename) +
                            "\" but support for libbz2 not compiled");
#endif  // FILEINTERFACE_HAVE_LIBBZ2
  } else {
    _input = new fileinterface::fileinterface_reader_flat;
  }
  _input->open(
      std::string(filename) +
      (_compress == GZIP ? ".gz" : (_compress == BZIP2 ? ".bz2" : "")));

  // read header data
  char buf[3];
  read(buf, 3);
  if (buf[0] != static_cast<char>(108) || buf[1] != static_cast<char>(27) ||
      buf[2] != static_cast<char>(1))
    throw std::domain_error(
        "fileinterface::plinkbed_reader::open: encountered "
        "unrecognized header data");
}

void fileinterface::plinkbed_reader::close() {
  if (_input) {
    _input->close();
    delete _input;
    _input = 0;
  }
}

void fileinterface::plinkbed_reader::clear() {
  if (_input) _input->clear();
}

bool fileinterface::plinkbed_reader::is_open() const {
  if (_input) return _input->is_open();
  return false;
}

char fileinterface::plinkbed_reader::get() {
  // probably not a thing that should really be allowed
  throw std::domain_error(
      "fileinterface::plinkbed_reader::get: functionality "
      "disabled for bed files");
}

bool fileinterface::plinkbed_reader::getline(std::string *line) {
  if (!line)
    throw std::domain_error(
        "fileinterface::plinkbed_reader::getline: "
        "called with null line pointer");
  // return it in format "120100012212012211200120012"....
  // coded allele is allele 1
  if (!_input)
    throw std::domain_error(
        "fileinterface::plinkbed_reader::getline: called on unopened "
        "file");

  // probe for eof
  try {
    read(_buf, 1);
    if (eof()) return false;
    //    std::cout << "single value grab successful" << std::endl;
  } catch (...) {
    return false;
  }

  *line = "";
  line->reserve(_line_length);
  // get the data
  if (_line_length_packed > 1) read(_buf + 1, _line_length_packed - 1);
  // convert the data
  unsigned total_count = 0;
  for (unsigned i = 0; i < _line_length_packed; ++i) {
    for (unsigned j = 0; j < 4 && total_count < _line_length;
         ++j, ++total_count) {
      *line += plink_packed_to_char(
          (static_cast<unsigned char>(_buf[i]) >> (2 * j)) & 3);
    }
  }
  return true;
}

bool fileinterface::plinkbed_reader::eof() const {
  if (_input) return _input->eof();
  return false;
}

bool fileinterface::plinkbed_reader::good() const {
  if (_input) return _input->good();
  return true;
}

bool fileinterface::plinkbed_reader::bad() const {
  if (_input) return _input->bad();
  return false;
}

void fileinterface::plinkbed_reader::read(char *buf, std::streamsize n) {
  if (_input) {
    _input->read(buf, n);
  } else {
    throw std::domain_error(
        "fileinterface::plinkbed_reader::read: called before file "
        "open");
  }
}

fileinterface::plinkbed_writer::plinkbed_writer(
    const std::string &compression_level)

    : fileinterface::fileinterface_writer(),
      _output(0),
      _buf(0),
      _line_length(0),
      _line_length_packed(0) {
  _compress = interpret_compression(compression_level);
}

void fileinterface::plinkbed_writer::open(const char *filename) {
  if (_output)
    throw std::domain_error(
        "fileinterface::plinkbed_writer::open: reopen attempted "
        "on active handle");
  if (_compress == GZIP) {
#ifdef FILEINTERFACE_HAVE_LIBZ
    _output = new fileinterface::fileinterface_writer_gzip;
#else
    throw std::domain_error("gzip compression requested for plinkbed write \"" +
                            std::string(filename) +
                            "\" but support for zlib not compiled");
#endif  // FILEINTERFACE_HAVE_LIBZ
  } else if (_compress == BZIP2) {
#ifdef FILEINTERFACE_HAVE_LIBBZ2
    _output = new fileinterface::fileinterface_writer_bzip2;
#else
    throw std::domain_error(
        "bzip2 compression requested for plinkbed write \"" +
        std::string(filename) + "\" but support for libbz2 not compiled");
#endif  // FILEINTERFACE_HAVE_LIBBZ2
  } else {
    _output = new fileinterface::fileinterface_writer_flat;
  }
  _output->open(
      std::string(filename) +
      (_compress == GZIP ? ".gz" : (_compress == BZIP2 ? ".bz2" : "")));

  // write header data
  char buf[3];
  buf[0] = static_cast<char>(108);
  buf[1] = static_cast<char>(27);
  buf[2] = static_cast<char>(1);
  write(buf, 3);
}

void fileinterface::plinkbed_writer::close() {
  if (_output) {
    _output->close();
    delete _output;
    _output = 0;
  }
}

void fileinterface::plinkbed_writer::clear() {
  if (_output) _output->clear();
}

bool fileinterface::plinkbed_writer::is_open() const {
  if (_output) return _output->is_open();
  return false;
}

void fileinterface::plinkbed_writer::put(char c) {
  throw std::domain_error(
      "fileinterface::plinkbed_writer::put: function disabled for "
      "plink bed");
}

void fileinterface::plinkbed_writer::writeline(const std::string &line) {
  if (!_output)
    throw std::domain_error(
        "fileinterface::plinkbed_writer::writeline: called on unopened "
        "file");
  //  std::cout << "writeline: encountered line \"" << line << "\" has length "
  //  << line.size() << std::endl;
  if (_line_length == _line_length_packed && !_line_length) {
    //    std::cout << "setting internals" << std::endl;
    _line_length = line.size();
    _line_length_packed = _line_length / 4 + (_line_length % 4 ? 1 : 0);
    if (_buf)
      throw std::domain_error(
          "fileinterface::plinkbed_writer::writeline: buffer allocated "
          "with 0 size?");
    _buf = new char[_line_length_packed];
  }

  if (line.size() != _line_length)
    throw std::domain_error(
        "fileinterface::plinkbed_writer::writeline: provided line does "
        "not match "
        "expected length: expected=" +
        fi_to_string<unsigned>(_line_length) +
        ", observed=" + fi_to_string<std::string::size_type>(line.size()));

  unsigned total_count = 0;
  for (unsigned i = 0; i < _line_length_packed; ++i) {
    _buf[i] = '\0';
    for (unsigned j = 0; j < 4 && total_count < _line_length;
         ++j, ++total_count) {
      _buf[i] =
          _buf[i] | (char_to_plink_packed(line.at(total_count)) << (2 * j));
    }
  }
  write(_buf, _line_length_packed);
}

void fileinterface::plinkbed_writer::write(char *buf, std::streamsize n) {
  if (_output) {
    _output->write(buf, n);
  } else {
    throw std::domain_error(
        "fileinterface::plinkbed_writer::write: called before file "
        "open");
  }
}

bool fileinterface::plinkbed_writer::eof() const {
  if (_output) return _output->eof();
  return false;
}

bool fileinterface::plinkbed_writer::good() const {
  if (_output) return _output->good();
  return true;
}

bool fileinterface::plinkbed_writer::fail() const {
  if (_output) return _output->fail();
  return false;
}

bool fileinterface::plinkbed_writer::bad() const {
  if (_output) return _output->bad();
  return false;
}
