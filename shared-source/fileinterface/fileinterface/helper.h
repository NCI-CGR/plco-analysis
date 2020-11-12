/*!
  \file helper.h
  \brief fileinterface utility functions
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#ifndef PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_HELPER_H_
#define PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_HELPER_H_

#include <sstream>
#include <stdexcept>
#include <string>

namespace fileinterface {
/*!
  \brief get platform-specific newline character
  \return platform-specific newline character
 */
inline std::string get_newline() {
#ifdef _WIN64
  return "\r\n";
#elif _WIN32
  return "\r\n";
#else  // if __APPLE__  // linux
  // #elif __linux || __unix
  return "\n";
#endif
}
/*!
  \brief convert object of arbitrary class to string with stringstreams
  @tparam value_type arbitrary input class
  @param obj instance of arbitrary input class to be converted
  \return input in string representation
 */
template <class value_type>
std::string fi_to_string(const value_type &obj) {
  std::ostringstream o;
  if (!(o << obj))
    throw std::domain_error("to_string: cannot convert object to string");
  return o.str();
}
}  // namespace fileinterface
#endif  // PLCO_ANALYSIS_SHARED_SOURCE_FILEINTERFACE_FILEINTERFACE_HELPER_H_
