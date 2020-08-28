/*!
  \file utilities.cc
  \brief implementations of nontemplated global utility functions
 */

#include "qsub_job_monitor/utilities.h"

bool qsub_job_monitor::cicompare(const std::string &s1,
				      const std::string &s2) {
  if (s1.size() == s2.size()) {
    for (unsigned i = 0; i < s1.size(); ++i) {
      if (tolower(s1.at(i)) != tolower(s2.at(i)))
	return false;
    }
    return true;
  }
  return false;
}
	
void qsub_job_monitor::splitline(const std::string &s,
				      std::vector<std::string> &vec,
				      const std::string &sep) {
  std::string::size_type loc = 0, cur = 0;
  vec.clear();
  while (true) {
    loc = s.find(sep, cur);
    if (loc == std::string::npos) {
      vec.push_back(s.substr(cur));
      break;
    }
    vec.push_back(s.substr(cur, loc - cur));
    cur = loc + sep.size();
  }
  return;
}

char qsub_job_monitor::reverse_complement(char c) {
  // for thoroughness, adding support for all nucleotide codes.
  // see also: https://www.bioinformatics.org/sms/iupac.html
  if (c == 'A') return 'T';
  if (c == 'T') return 'A';
  if (c == 'G') return 'C';
  if (c == 'C') return 'G';
  if (c == 'a') return 't';
  if (c == 't') return 'a';
  if (c == 'g') return 'c';
  if (c == 'c') return 'g';
  if (c == '1') return '4';
  if (c == '2') return '3';
  if (c == '3') return '2';
  if (c == '4') return '1';
  if (c == 'R') return 'Y';
  if (c == 'Y') return 'R';
  if (c == 'S') return 'W';
  if (c == 'W') return 'S';
  if (c == 'K') return 'M';
  if (c == 'M') return 'K';
  if (c == 'B') return 'V';
  if (c == 'V') return 'B';
  if (c == 'D') return 'H';
  if (c == 'H') return 'D';
  if (c == 'r') return 'y';
  if (c == 'y') return 'r';
  if (c == 's') return 'w';
  if (c == 'w') return 's';
  if (c == 'k') return 'm';
  if (c == 'm') return 'k';
  if (c == 'b') return 'v';
  if (c == 'v') return 'b';
  if (c == 'd') return 'h';
  if (c == 'h') return 'd';
  return c;
}

std::string qsub_job_monitor::reverse_complement(const std::string &s) {
  std::string t = "";
  std::vector<std::string> split_alleles;
  // assuming the possibility of VCF-style alternate alleles with comma delimiters
  splitline(s, split_alleles, ",");
  std::ostringstream o;
  // for each split out allele
  for (unsigned i = 0; i < split_alleles.size(); ++i) {
    t = s;
    // go through and actually flip everything
    for (unsigned j = 0; j < s.size(); ++j) {
      t.at(j) = reverse_complement(s.at(s.size() - j - 1));
    }
    // report the results in the same order as input
    if (i) {
      if (!(o << ','))
	throw std::domain_error("reverse_complement: cannot emit delimiter to stream");
    }
    if (!(o << t))
      throw std::domain_error("reverse_complement: cannot emit flipped allele to stream");
  }
  return o.str();
}

unsigned qsub_job_monitor::get_bin_index(const double &p,
					      unsigned total_bins) {
  unsigned res = 0;
  if (fabs(p) < DBL_EPSILON) res = 0;
  else if (p - 1.0 >= -DBL_EPSILON) res = total_bins - 1;
  else res = ceil(p * static_cast<double>(total_bins)) - 1;
  if (res > 1000000)
    throw std::domain_error("get_bin_index: likely underflow error for "
			    "result " + to_string<unsigned>(res) + " with probability "
			    + to_string<double>(p) + " and storage size " + to_string<unsigned>(total_bins));
  return res;
}


//from https://stackoverflow.com/questions/478898/how-do-i-execute-a-command-and-get-the-output-of-the-command-within-c-using-po

int qsub_job_monitor::exec(const char *cmd, std::string &screenoutput) {
  char buffer[128];
  screenoutput = "";
  FILE *pipe = 0;
  try {
    pipe = popen(cmd, "r");
    if (!pipe) throw std::runtime_error("popen() failed");
    while (fgets(buffer, sizeof buffer, pipe) != NULL) {
      screenoutput += buffer;
    }
    return pclose(pipe);
  } catch (...) {
    pclose(pipe);
    throw;
  }
}

int qsub_job_monitor::exec(const std::string &cmd, std::string &screenoutput) {
  return exec(cmd.c_str(), screenoutput);
}

void qsub_job_monitor::get_job_ids(const std::string &qstat,
				   std::map<unsigned, bool> &target) {
  std::vector<std::string> lines;
  unsigned jobid = 0;
  target.clear();
  splitline(qstat, lines, "\n");
  std::vector<std::string>::const_iterator line = lines.begin();
  for (unsigned i = 0; i < 2; ++i, ++line) {
    if (line == lines.end()) throw std::domain_error("inadequate total line count in qstat data: \"" + qstat + "\"");
  }
  for (; line != lines.end(); ++line) {
    if (line->empty()) continue;
    std::istringstream strm1(*line);
    if (!(strm1 >> jobid))
      throw std::domain_error("cannot parse qstat line \"" + *line + "\"");
    target[jobid] = true;
  }
}

unsigned qsub_job_monitor::get_job_id(const std::string &echo_output) {
  std::istringstream strm1(echo_output);
  std::string catcher = "";
  unsigned res = 0;
  if (!(strm1 >> catcher >> catcher >> res))
    throw std::domain_error("cannot parse job id from echo output \"" + echo_output + "\"");
  return res;
}

