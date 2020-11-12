/*!
  \file utilities.h
  \brief general global utility functions in namespace
  \author Cameron Palmer
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer
*/

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_QSUB_JOB_MONITOR_QSUB_JOB_MONITOR_UTILITIES_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_QSUB_JOB_MONITOR_QSUB_JOB_MONITOR_UTILITIES_H_

#include <cfloat>
#include <cmath>
#include <cstdio>
#include <map>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace qsub_job_monitor {
/*!
  \brief convert arbitrary object to string representation
  @tparam value_type input class for conversion
  @param obj input object to be converted to string
  \return string representation of input parameter
  \warning requires support for object class with stringstreams
*/
template <class value_type>
std::string to_string(const value_type &obj) {
  std::ostringstream o;
  if (!(o << obj))
    throw std::domain_error("to_string: cannot convert object to string");
  return o.str();
}

/*!
  \brief convert string to arbitrary class representation
  @tparam value_type output class for conversion
  @param s input string to be converted to new class
  \return new class representation of input string
  \warning requires support for object class with stringstream
*/
template <class value_type>
value_type from_string(const std::string &s) {
  std::istringstream strm1(s);
  value_type res;
  if (!(strm1 >> res))
    throw std::domain_error(
        "from_string: cannot convert string "
        "to object: \"" +
        s + "\"");
  return res;
}

/*!
  \brief perform case-insensitive comparison for identity of two strings
  @param s1 first string for comparison
  @param s2 second string for comparison
  \return whether the two input strings are case-insensitive identical
*/
bool cicompare(const std::string &s1, const std::string &s2);
/*!
  \brief split a string into tokens based on arbitrary delimiter
  @param s string in need of parsing
  @param vec where the tokenized result will be stored
  @param sep arbitrary delimiter used to denote tokens
  \warning data present in vec will be purged before adding results
*/
void splitline(const std::string &s, std::vector<std::string> *vec,
               const std::string &sep);
/*!
  \brief get nucleotide complement to a given nucleotide
  @param c nucleotide in need of complementing
  \return complement of input

  This function supports all nucleotide codes for some reason.
  Numeric encodings 1-4 assume complements 4-1 respectively.
*/
char reverse_complement(char c);
/*!
  \brief get reverse complement of arbitrary set of nucleotides
  @param s set of nucleotides in need of complementing
  \return complement of input

  This function accepts VCF-style alternate alleles for complex variants,
  delimited by commas. In that case, each allele is split out and RCed
  separately, and the alleles are returned in the same order as input.
*/
std::string reverse_complement(const std::string &s);
/*!
  \brief take a value on [0,1] and map it to one of a fixed number of bins
  @param p value on [0,1] to map
  @param total_bins total number of bins in which to
  approximately equipartition unit interval
  \return computed index on [0,total_bins)

  \warning behavior is to map 0 to the first bin, and then have every
  other bin be half-open lower
*/
unsigned get_bin_index(const double &p, unsigned total_bins);

// from
// https://stackoverflow.com/questions/478898/how-do-i-execute-a-command-and-get-the-output-of-the-command-within-c-using-po
int exec(const char *cmd, std::string *screenoutput);
int exec(const std::string &cmd, std::string *screenoutput);
void get_job_ids(const std::string &qstat, std::map<unsigned, bool> *target);
unsigned get_job_id(const std::string &echo_output);
void kill_job(unsigned jobid);
}  // namespace qsub_job_monitor

#endif  // PLCO_ANALYSIS_SHARED_SOURCE_QSUB_JOB_MONITOR_QSUB_JOB_MONITOR_UTILITIES_H_
