# Automake file

ACLOCAL_AMFLAGS = -I m4
# Build rules for libraries.
noinst_LIBRARIES = libfileinterface.a

libfileinterface_a_SOURCES = fileinterface/fileinterface_reader_bzip2.cc \
  fileinterface/fileinterface_reader_flat.cc \
  fileinterface/fileinterface_writer_bzip2.cc \
  fileinterface/fileinterface_writer_flat.cc \
  fileinterface/fileinterface_reader_gzip.cc \
  fileinterface/fileinterface_writer_gzip.cc \
  fileinterface/plinkbed.cc \
  fileinterface/fileinterface_reader.h \
  fileinterface/fileinterface_reader_parent.h \
  fileinterface/fileinterface_reader_bzip2.h \
  fileinterface/fileinterface_reader_flat.h \
  fileinterface/fileinterface_reader_gzip.h \
  fileinterface/fileinterface_writer.h \
  fileinterface/fileinterface_writer_parent.h \
  fileinterface/fileinterface_writer_bzip2.h \
  fileinterface/fileinterface_writer_flat.h \
  fileinterface/fileinterface_writer_gzip.h \
  fileinterface/helper.h \
  fileinterface/plinkbed.h \
  fileinterface/fileinterface.h \
  fileinterface/config.h

##libfileinterface_a_LDFLAGS = -version-info 1:0:0

dist_doc_DATA = README
#ACLOCAL_AMFLAGS = -I m4
