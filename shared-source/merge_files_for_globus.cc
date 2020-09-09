#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <map>
#include <utility>
#include <stdexcept>
#include <cctype>
#include <boost/smart_ptr.hpp>
#include "fileinterface/fileinterface.h"

using namespace imputation_comparison;

template <class value_type>
value_type from_string(const std::string &str) {
  std::istringstream strm1(str);
  value_type res;
  if (!(strm1 >> res))
    throw std::domain_error("cannot convert string to object: \"" + str + "\"");
  return res;
}

template <class value_type>
std::string to_string(const value_type &obj) {
  std::ostringstream o;
  if (!(o << obj))
    throw std::domain_error("cannot convert object to string");
  return o.str();
}

void splitline(const std::string &s,
	       std::vector<std::string> &vec,
	       const std::string &sep) {
  vec.clear();
  std::string::size_type loc = 0, cur = 0;
  while (true) {
    loc = s.find(sep, cur);
    if (loc == std::string::npos) {
      vec.push_back(s.substr(cur));
      break;
    }
    vec.push_back(s.substr(cur, loc - cur));
    cur = loc + sep.size();
  }
}

bool cicompare(const std::string &s1, const std::string &s2) {
  if (s1.size() != s2.size()) return false;
  for (unsigned i = 0; i < s1.size(); ++i) {
    if (s1.at(i) != s2.at(i)) return false;
  }
  return true;
}

class annotation {
public:
  annotation() {}
  annotation(const annotation &obj)
    : _pos(obj._pos),
      _id(obj._id),
      _ref(obj._ref),
      _alt(obj._alt),
      _tags(obj._tags),
      _freqs(obj._freqs),
      _betas(obj._betas),
      _ses(obj._ses),
      _ps(obj._ps),
      _ns(obj._ns),
      _phets(obj._phets) {}
  ~annotation() throw() {}
		
  void add_data(const std::string &tag,
		unsigned pos,
		const std::string &id,
		const std::string &ref,
		const std::string &alt,
		const std::string &freq,
		const double &beta,
		const double &se,
		const double &p,
		unsigned n,
		const double &phet) {
    if (_tags.find(tag) != _tags.end()) {
      throw std::domain_error("attempted to double-add data for \"" + tag + "\"");
    }
    _tags[tag] = _freqs.size();
    _pos = pos;
    _id = id;
    _ses.push_back(se);
    _ps.push_back(p);
    _ns.push_back(n);
    _phets.push_back(phet);
    if (_ref.empty() && _alt.empty()) {
      _ref = ref;
      _alt = alt;
      _betas.push_back(beta);
      _freqs.push_back(freq);
    } else if (_ref.empty() || _alt.empty()) {
      throw std::domain_error("partial allele completion :(");
    } else if (!_ref.compare(ref) && !_alt.compare(alt)) {
      _freqs.push_back(freq);
      _betas.push_back(beta);
    } else if (!_alt.compare(ref) && !_ref.compare(alt)) {
      if (freq.find_first_not_of("1234567890.") != std::string::npos) {
	_freqs.push_back(freq);
      } else {
	_freqs.push_back(to_string<double>(1.0 - from_string<double>(freq)));
      }
      _betas.push_back(-1.0 * beta);
    } else {
      throw std::domain_error("impossible allele incompatibility");
    }
  }
		
  void report_entry(const std::string &tag,
		    bool first,
		    bool report_frequency,
		    std::ostringstream &o) {
    std::map<std::string, unsigned>::const_iterator finder;
    if (first) {
      o << '\t' << _pos << '\t' << _id << '\t' << _ref << '\t' << _alt;
    }
    if ((finder = _tags.find(tag)) == _tags.end()) {
      for (unsigned i = 0; i < (report_frequency ? 6 : 5); ++i) {
	o << "\tNA";
      }
    } else {
      if (report_frequency) {
	o << '\t' << _freqs.at(finder->second);
      }
      if (_betas.at(finder->second) != _betas.at(finder->second)) {
	o << "\tNA\tNA";
      } else {
	o << '\t' << _betas.at(finder->second)
	  << '\t' << _ses.at(finder->second);
      }
      o << '\t' << _ps.at(finder->second)
	<< '\t' << _ns.at(finder->second);
      if (_phets.at(finder->second) != _phets.at(finder->second)) {
	o << "\tNA";
      } else {
	o << '\t' << _phets.at(finder->second);
      }
    }
  }
private:
  unsigned _pos;
  std::string _id;
  std::string _ref;
  std::string _alt;
  std::map<std::string, unsigned> _tags;
  std::vector<std::string> _freqs;
  std::vector<double> _betas;
  std::vector<double> _ses;
  std::vector<double> _ps;
  std::vector<unsigned> _ns;
  std::vector<double> _phets;
};

void read_data(const std::string &filename,
	       const std::string &file_tag,
	       std::vector<std::map<std::string, boost::shared_ptr<annotation> > > &target) {
  fileinterface_reader *input = 0;
  std::string line = "", id = "", ref = "", alt = "", freq = "";
  double beta = 0.0, se = 0.0, p = 0.0, hetp = 0.0;
  unsigned chr = 0, pos = 0, n = 0;
  bool categorical_override = false;
  std::vector<std::string> vec;
  std::map<std::string, boost::shared_ptr<annotation> >::iterator finder;
  try {
    input = reconcile_reader(filename);
    input->getline(line);
    categorical_override = line.find("P_CONSENSUS") != std::string::npos;
    while (input->getline(line)) {
      std::istringstream strm1(line);
      if (categorical_override) {
	splitline(line, vec, "\t");
	if (vec.size() < 10) {
	  throw std::runtime_error("categorical type file \"" + filename + "\" had insufficient line entries :(");
	}
	chr = from_string<unsigned>(vec.at(0));
	pos = from_string<unsigned>(vec.at(1));
	id = vec.at(2);
	ref = vec.at(3);
	alt = vec.at(4);
	freq = vec.at(5);
	beta = se = hetp = 1.0 / 0.0;
	p = from_string<double>(vec.at(vec.size() - 2));
	n = from_string<unsigned>(vec.at(vec.size() - 1));
      } else {
	if (!(strm1 >> chr >> pos >> id >> ref >> alt >> freq >> beta >> se >> p >> n >> hetp))
	  throw std::domain_error("cannot read file \"" + filename + "\" line \"" + line + "\"");
      }
      if (target.size() < chr) target.resize(chr);
      if ((finder = target.at(chr-1).find(id.substr(id.find(":") + 1))) == target.at(chr-1).end()) {
	boost::shared_ptr<annotation> ptr(new annotation);
	finder = target.at(chr-1).insert(std::make_pair(id.substr(id.find(":") + 1), ptr)).first;
      }
      finder->second->add_data(file_tag, pos, id, ref, alt, freq, beta, se, p, n, hetp);
    }
    input->close();
    delete input;
    input = 0;
  } catch (...) {
    if (input) delete input;
    throw;
  }
}

void write_data(const std::string &filename,
		const std::map<std::string, std::map<std::string, std::string> > &file_linker,
		const std::vector<std::map<std::string, boost::shared_ptr<annotation> > > &target) {
  fileinterface_writer *output = 0;
  try {
    output = reconcile_writer(filename);
    std::ostringstream header;
    header << "CHR\tPOS\tSNP\tTested_Allele\tOther_Allele";
    for (std::map<std::string, std::map<std::string, std::string> >::const_iterator iter1 = file_linker.begin();
	 iter1 != file_linker.end();
	 ++iter1) {
      header << "\tFREQ_" << iter1->first;
      for (std::map<std::string, std::string>::const_iterator iter2 = iter1->second.begin();
	   iter2 != iter1->second.end();
	   ++iter2) {
	header << "\tBETA_" << iter1->first << "_" << iter2->first
	       << "\tSE_" << iter1->first << "_" << iter2->first
	       << "\tP_" << iter1->first << "_" << iter2->first
	       << "\tN_" << iter1->first << "_" << iter2->first
	       << "\tPHet_" << iter1->first << "_" << iter2->first;
      }
    }
    output->writeline(header.str());
    for (unsigned i = 0; i < target.size(); ++i) {
      for (std::map<std::string, boost::shared_ptr<annotation> >::const_iterator iter = target.at(i).begin();
	   iter != target.at(i).end();
	   ++iter) {
	std::ostringstream o;
	o << (i+1);
	for (std::map<std::string, std::map<std::string, std::string> >::const_iterator iter1 = file_linker.begin();
	     iter1 != file_linker.end();
	     ++iter1) {
	  for (std::map<std::string, std::string>::const_iterator iter2 = iter1->second.begin();
	       iter2 != iter1->second.end();
	       ++iter2) {
	    iter->second->report_entry(iter1->first + "_" + iter2->first,
				       iter1 == file_linker.begin() && iter2 == iter1->second.begin(),
				       iter2 == iter1->second.begin(),
				       o);
	  }
	}
	output->writeline(o.str());
      }
    }
    output->close();
    delete output;
    output = 0;
  } catch (...) {
    if (output) delete output;
    throw;
  }
}

std::string determine_sex_from_file(const std::string &s) {
  std::string filename = s;
  if (filename.find("/") != std::string::npos) filename = filename.substr(filename.rfind("/") + 1);
  std::string phenotype = filename.substr(0, filename.find("."));
  if (phenotype.find("_female") == phenotype.size() - 7) {
    return "female";
  } else if (phenotype.find("_male") == phenotype.size() - 5) {
    return "male";
  } else {
    return "all";
  }
}

std::string determine_ancestry_from_file(const std::string &s) {
  std::string filename = s;
  if (filename.find("/") != std::string::npos) filename = filename.substr(filename.rfind("/") + 1);
  filename = filename.substr(filename.find(".") + 1);
  std::string ancestry = filename.substr(0, filename.find("."));
  return ancestry;
}

int main(int argc, char **argv) {
  if (argc < 4) {
    throw std::domain_error("usage: \"" + std::string(argv[0]) + " [assorted analysis files] output_filename [yes sex-specific or no]\"");
  }
  std::string results_dir = std::string(argv[1]);
  std::string output_filename = std::string(argv[argc - 2]);
  std::string sex_specific = std::string(argv[argc - 1]);
  // create output slots for each ancestry and sex analysis
  std::map<std::string, std::string> sex_linker;
  sex_linker["all"] = "";
  if (cicompare(sex_specific, "yes")) {
    sex_linker["female"] = "";
    sex_linker["male"] = "";
  }
  std::map<std::string, std::map<std::string, std::string> > file_linker;
  file_linker["East_Asian"] = sex_linker;
  file_linker["European"] = sex_linker;
  for (int i = 1; i < (argc-2); ++i) {
    std::string filename = std::string(argv[i]);
    // identify the type of file
    std::string sex = determine_sex_from_file(filename);
    std::string ancestry = determine_ancestry_from_file(filename);
    file_linker[ancestry][sex] = filename;
  }
  // report all the results, aligned by variant
  std::vector<std::map<std::string, boost::shared_ptr<annotation> > > all_data;
  all_data.reserve(22);
  for (std::map<std::string, std::map<std::string, std::string> >::const_iterator iter1 = file_linker.begin();
       iter1 != file_linker.end();
       ++iter1) {
    for (std::map<std::string, std::string>::const_iterator iter2 = iter1->second.begin();
	 iter2 != iter1->second.end();
	 ++iter2) {
      if (!iter2->second.empty()) {
	std::cout << "reading data from file \"" << iter2->second << "\"" << std::endl;
	read_data(iter2->second, iter1->first + "_" + iter2->first, all_data);
      }
    }
  }
  // have to determine if lack of sex-specific files was intentional :(
	
  std::cout << "writing results to file" << std::endl;
  write_data(output_filename, file_linker, all_data);
  std::cout << "all done: " << output_filename << std::endl;
  return 0;
}
