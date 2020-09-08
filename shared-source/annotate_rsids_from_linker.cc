#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <map>
#include <utility>
#include <stdexcept>
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

void splitline(const std::string &line,
	       std::vector<std::string> &vec,
	       const std::string &sep) {
  vec.clear();
  std::string::size_type loc = 0, cur = 0;
  while (true) {
    loc = line.find(sep, cur);
    if (loc == std::string::npos) {
      vec.push_back(line.substr(cur));
      break;
    }
    vec.push_back(line.substr(cur, loc - cur));
    cur = loc + sep.size();
  }
}

class rescue_annotation {
public:
  rescue_annotation()
    : _input_index(0),
      _ref(""),
      _alt(""),
      _updated_id("") {}
  rescue_annotation(const rescue_annotation &obj)
    : _input_index(obj._input_index),
      _ref(obj._ref),
      _alt(obj._alt),
      _updated_id(obj._updated_id) {}
  ~rescue_annotation() throw() {}
		
  void set_index(unsigned u) {_input_index = u;}
  unsigned get_index() const {return _input_index;}
  void set_ref(const std::string &s) {_ref = s;}
  const std::string &get_ref() const {return _ref;}
  void set_alt(const std::string &s) {_alt = s;}
  const std::string &get_alt() const {return _alt;}
  void set_updated_id(const std::string &s) {_updated_id = s;}
  const std::string &get_updated_id() const {return _updated_id;}

  bool alleles_consistent(const std::string &ref, const std::string &alt) const;
private:
  unsigned _input_index;
  std::string _ref;
  std::string _alt;
  std::string _updated_id;
};

bool rescue_annotation::alleles_consistent(const std::string &ref, const std::string &alt) const {
  std::vector<std::string> split_alt;
  splitline(alt, split_alt, ",");
  bool test_against_alt = !ref.compare(get_ref());
  bool test_against_ref = !ref.compare(get_alt());
  if (test_against_ref || test_against_alt) {
    for (std::vector<std::string>::const_iterator iter = split_alt.begin(); iter != split_alt.end(); ++iter) {
      if (!iter->compare(test_against_ref ? get_ref() : (test_against_alt ? get_alt() : std::string("")))) {
	return true;
      }
    }
  }
  return false;
}

void stream_update(const std::string &analysis_filename,
		   const std::string &linker_filename,
		   const std::string &output_filename,
		   std::vector<std::string> *updated_ids,
		   std::map<std::string, rescue_annotation> *rescue_chrpos) {
  fileinterface_reader *input_analysis = 0, *input_linker = 0;
  fileinterface_writer *output = 0;
  std::string analysis_line = "", linker_line = "", chrpos_id = "", rsid = "", analysis_chrpos = "", catcher = "", refalt = "";
  std::string::size_type loc = 0;
  unsigned total_updated = 0, valid_updated = 0, not_present_in_linker = 0, linker_chr = 0, linker_pos = 0, analysis_chr = 0, analysis_pos = 0;
  try {
    input_analysis = reconcile_reader(analysis_filename);
    input_linker = reconcile_reader(linker_filename);
    input_analysis->getline(analysis_line);
    if (!updated_ids) {
      output = reconcile_writer(output_filename);
      output->writeline(analysis_line);
    } else {
      updated_ids->reserve(40000000);
    }
    while (input_analysis->getline(analysis_line)) {
      std::istringstream strm1(analysis_line);
      if (!(strm1 >> analysis_chr >> analysis_pos >> analysis_chrpos))
	throw std::domain_error("unable to parse analysis file \"" + analysis_filename + "\" line \"" + analysis_line + "\"");
      refalt = analysis_chrpos.substr(analysis_chrpos.find(":", analysis_chrpos.find(":") + 1) + 1);
      while (true) {
	if (linker_line.empty()) {
	  if (!input_linker->getline(linker_line)) break;
	}
	std::istringstream strm2(linker_line);
	if (!(strm2 >> chrpos_id >> rsid))
	  throw std::domain_error("unable to parse linker file \"" + linker_filename + "\" line \"" + linker_line + "\"");
	loc = chrpos_id.find(":") + 1;
	linker_chr = from_string<unsigned>(chrpos_id.substr(3, loc - 4));
	linker_pos = from_string<unsigned>(chrpos_id.substr(loc, chrpos_id.find(":", loc) - loc));
	if (!chrpos_id.compare(analysis_chrpos)) {
	  ++total_updated;
	  if (rsid.compare(".")) ++valid_updated;
	  else rsid = analysis_chrpos;
	  if (output) {
	    std::ostringstream o;
	    o << analysis_chr << '\t' << analysis_pos << '\t' << rsid << ":" << refalt;
	    while (strm1 >> catcher) {
	      o << '\t' << catcher;
	    }
	    output->writeline(o.str());
	  } else {
	    // store information
	    updated_ids->push_back(rsid);
	    if (!rsid.compare(analysis_chrpos)) {
	      rescue_annotation ra;
	      ra.set_index(updated_ids->size() - 1);
	      rescue_chrpos->insert(std::make_pair(analysis_chrpos, ra));
	    }
	  }
	  //if (total_updated % 1000 == 0) {
	  //	std::cout << "\tupdated " << total_updated << std::endl;
	  //}
	  linker_line = "";
	  break;
	} else if ((linker_chr == analysis_chr && linker_pos > analysis_pos) || linker_chr > analysis_chr) {
	  // something terrible has happened with the linker, flush the analysis result without an ID
	  ++not_present_in_linker;
	  if (output) {
	    std::ostringstream o;
	    o << analysis_chr << '\t' << analysis_pos << "\t" << analysis_chrpos;
	    while (strm1 >> catcher) o << '\t' << catcher;
	    output->writeline(o.str());
	  } else {
	    // store information
	    updated_ids->push_back(analysis_chrpos);
	    rescue_annotation ra;
	    ra.set_index(updated_ids->size() - 1);
	    rescue_chrpos->insert(std::make_pair(analysis_chrpos, ra));
	  }
	  break;
	} else {
	  linker_line = "";
	}
      }
    }
    input_analysis->close();
    delete input_analysis;
    input_linker->close();
    delete input_linker;
    if (output) {
      output->close();
      delete output;
      std::cout << output_filename << ": updated " << total_updated << ", of which " << valid_updated << " had nonmissing rsids; " << not_present_in_linker << " were either absent from the linker or unsorted and have been set to \".\"" << std::endl;
    } else {
      std::cout << "from first pass, updated " << valid_updated << ", didn't manage to update " << (total_updated - valid_updated + not_present_in_linker) << std::endl;
    }
  } catch (...) {
    if (input_analysis) delete input_analysis;
    if (input_linker) delete input_linker;
    if (output) delete output;
    throw;
  }
}

void dbsnp_rescue(const std::string &filename,
		  std::map<std::string, rescue_annotation> &target) {
  fileinterface_reader *input = 0;
  std::string line = "";
  unsigned n_updated = 0;
  std::map<std::string, rescue_annotation>::iterator finder;
  std::vector<std::string> vec;
  try {
    input = reconcile_reader(filename);
    while (input->getline(line) && n_updated != target.size()) {
      if (line.empty() || line.at(0) == '#') continue;
      splitline(line, vec, "\t");
      //std::istringstream strm1(line);
      //if (!(strm1 >> chr >> pos >> id >> ref >> alt))
      //	throw std::domain_error("cannot parse dbsnp file \"" + filename + "\" line \"" + line + "\"");
      if (vec.size() < 5) throw std::domain_error("inadequate entries on dbsnp line \"" + line + "\"");
      if (vec.at(4).empty()) vec.at(4) = ".";
      if ((finder = target.find(vec.at(0) + ":" + vec.at(1))) != target.end()) {
	if (finder->second.alleles_consistent(vec.at(3), vec.at(4))) {
	  finder->second.set_updated_id(vec.at(2));
	  ++n_updated;
	}
      }
    }
    input->close();
    delete input;
    input = 0;
    std::cout << "of " << target.size() << " possible updates, updated " << n_updated << " (" << (static_cast<double>(n_updated) / target.size()) << ")" << std::endl;
  } catch (...) {
    if (input) delete input;
    throw;
  }
}

void update_from_memory(const std::string &input_filename,
			std::vector<std::string> &updated_ids,
			const std::map<std::string, rescue_annotation> &rescued_ids,
			const std::string &output_filename) {
  fileinterface_reader *input = 0;
  fileinterface_writer *output = 0;
  std::string line = "", catcher = "", refalt = "";
  try {
    input = reconcile_reader(input_filename);
    output = reconcile_writer(output_filename);
    for (std::map<std::string, rescue_annotation>::const_iterator iter = rescued_ids.begin(); iter != rescued_ids.end(); ++iter) {
      if (!iter->second.get_updated_id().empty()) {
	updated_ids.at(iter->second.get_index()) = iter->second.get_updated_id();
      }
    }
    input->getline(line);
    output->writeline(line);
    unsigned counter = 0;
    while (input->getline(line)) {
      std::istringstream strm1(line);
      std::ostringstream o;
      for (unsigned i = 0; i < 2; ++i) {
	strm1 >> catcher;
	if (i) o << '\t';
	o << catcher;
      }
      strm1 >> catcher;
      refalt = catcher.substr(catcher.find(":", catcher.find(":") + 1) + 1);
      o << '\t' << updated_ids.at(counter) << ":" << refalt;
      while (strm1 >> catcher) o << '\t' << catcher;
      output->writeline(o.str());
      ++counter;
    }
    input->close();
    delete input;
    input = 0;
    output->close();
    delete output;
    output = 0;
  } catch (...) {
    if (input) delete input;
    if (output) delete output;
    throw;
  }
}

int main(int argc, char **argv) {
  if (argc < 4)
    throw std::domain_error("usage: \"" + std::string(argv[0]) + " input_analysis_filename linker_filename [dbsnp_vcf_filename] output_filename\"");
  std::string analysis_filename = std::string(argv[1]);
  std::string linker_filename = std::string(argv[2]);
  std::string dbsnp_filename = "";
  if (argc > 4) dbsnp_filename = std::string(argv[3]);
  std::string output_filename = std::string(argv[argc == 4 ? 3 : 4]);
  std::vector<std::string> updated_ids;
  std::map<std::string, rescue_annotation> rescue_chrpos;
  std::cout << "starting run for output " << output_filename << std::endl;
  if (dbsnp_filename.empty()) {
    std::cout << "running one-shot against prepared linker file " << linker_filename << std::endl;
  } else {
    std::cout << "running multipass run against dbSNP " << dbsnp_filename << " with a preprocessing step against the linker " << linker_filename << std::endl;
  }
  std::cout << "running stream_update against linker" << std::endl;
  stream_update(analysis_filename, linker_filename, dbsnp_filename.empty() ? output_filename : std::string(""), dbsnp_filename.empty() ? NULL : &updated_ids, dbsnp_filename.empty() ? NULL : &rescue_chrpos);
  if (!rescue_chrpos.empty()) {
    std::cout << "running rescue pass against dbSNP for " << rescue_chrpos.size() << " variants" << std::endl;
    dbsnp_rescue(dbsnp_filename, rescue_chrpos);
  }
  if (!updated_ids.empty()) {
    std::cout << "emitting consensus results from both passes to " << output_filename << std::endl;
    update_from_memory(analysis_filename, updated_ids, rescue_chrpos, output_filename);
  }
  return 0;
}
