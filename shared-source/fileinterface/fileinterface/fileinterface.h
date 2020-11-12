/*!
  \file fileinterface.h
  \brief main entry point for fileinterface classes. Pulls in other headers
  and provides primary IO utility functions.
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_H_

#include <iostream>
#include <string>

#include "fileinterface/fileinterface_reader.h"
#include "fileinterface/fileinterface_writer.h"
#include "fileinterface/plinkbed.h"

namespace fileinterface {
/*!
  \brief utility function to facilitate file input while respecting compression
  suffixes
  @param filename name of file to be opened
  \return pointer to allocated object
  \warning compression type is determined from suffix of provided file
  \warning memory must be managed by caller
 */
inline fileinterface_reader *reconcile_reader(const std::string &filename) {
  fileinterface::fileinterface_reader *ptr = 0;
  /*if (filename.find(".bed.gz") == filename.size() - 7) {
    ptr = new fileinterface::plinkbed_reader("gzip");
    ptr->open(filename);
  } else if (filename.find(".bed.bz2") == filename.size() - 8) {
    ptr = new fileinterface::plinkbed_reader("bzip2");
    ptr->open(filename);
    } else if (filename.find(".bed") == filename.size() - 4) {
    ptr = new fileinterface::plinkbed_reader("none");
    ptr->open(filename);
    } else */
  if (filename.find(".gz") == filename.size() - 3) {
#ifdef FILEINTERFACE_HAVE_LIBZ
    ptr = new fileinterface::fileinterface_reader_gzip;
    ptr->open(filename);
#else
    throw std::domain_error(
        "zlib support not compiled into software, cannot open \"" + filename +
        "\"");
#endif  // FILEINTERFACE_HAVE_LIBZ
  } else if (filename.find(".bz2") == filename.size() - 4) {
#ifdef FILEINTERFACE_HAVE_LIBBZ2
    ptr = new fileinterface::fileinterface_reader_bzip2;
    ptr->open(filename);
#else
    throw std::domain_error(
        "libbz2 support not compiled into software, cannot open \"" + filename +
        "\"");
#endif  // FILEINTERFACE_HAVE_LIBBZ2
  } else {
    ptr = new fileinterface::fileinterface_reader_flat;
    ptr->open(filename);
  }
  return ptr;
}
/*!
  \brief utility function to facilitate file output while respecting compression
  suffixes
  @param filename name of file to be opened
  \return pointer to allocated object
  \warning compression type is determined from suffix of provided file
  \warning memory must be managed by caller
 */
inline fileinterface_writer *reconcile_writer(const std::string &filename) {
  fileinterface::fileinterface_writer *ptr = 0;
  if (filename.find(".gz") == filename.size() - 3) {
#ifdef FILEINTERFACE_HAVE_LIBZ
    ptr = new fileinterface::fileinterface_writer_gzip;
    ptr->open(filename);
#else
    throw std::domain_error(
        "zlib support not compiled into software, cannot write \"" + filename +
        "\"");
#endif  // FILEINTERFACE_HAVE_LIBZ
  } else if (filename.find(".bz2") == filename.size() - 4) {
#ifdef FILEINTERFACE_HAVE_LIBBZ2
    ptr = new fileinterface::fileinterface_writer_bzip2;
    ptr->open(filename);
#else
    throw std::domain_error(
        "libbz2 support not compiled into software, cannot write \"" +
        filename + "\"");
#endif  // FILEINTERFACE_HAVE_LIBBZ2
  } else {
    ptr = new fileinterface::fileinterface_writer_flat;
    ptr->open(filename);
  }
  return ptr;
}
}  // namespace fileinterface

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_FILEINTERFACE_H_
