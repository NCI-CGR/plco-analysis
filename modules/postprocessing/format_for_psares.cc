/*!
  \file format_for_psares.cc
  \brief convert pipeline output files to format
  compliant with Sonja Berndt PSA residual analysis
  \copyright Released under the MIT License.
  Copyright 2020 Cameron Palmer.
 */

#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "fileinterface/fileinterface.h"

namespace format_for_psares {

template <class value_type>
value_type from_string(const std::string &str) {
  std::istringstream strm1(str);
  value_type res;
  if (!(strm1 >> res))
    throw std::runtime_error(
        "cannot convert string "
        "to object: \"" +
        str + "\"");
  return res;
}

void splitline(const std::string &s, std::vector<std::string> *vec,
               const std::string &sep) {
  if (!vec) throw std::runtime_error("splitline: null vector pointer");
  vec->clear();
  std::string::size_type loc = 0, cur = 0;
  while (true) {
    loc = s.find(sep, cur);
    if (loc == std::string::npos) {
      vec->push_back(s.substr(cur));
      break;
    }
    vec->push_back(s.substr(cur, loc - cur));
    cur = loc + sep.size();
  }
}

std::string strsubst(const std::string &s, char query, char replacement) {
  std::string res = s;
  for (std::string::iterator iter = res.begin(); iter != res.end(); ++iter) {
    if (*iter == query) *iter = replacement;
  }
  return res;
}

std::string to_lower(const std::string &s) {
  std::string res = s;
  for (std::string::iterator iter = res.begin(); iter != res.end(); ++iter) {
    *iter = tolower(*iter);
  }
  return res;
}

std::string to_upper(const std::string &s) {
  std::string res = s;
  for (std::string::iterator iter = res.begin(); iter != res.end(); ++iter) {
    *iter = toupper(*iter);
  }
  return res;
}

class path_processor {
 public:
  path_processor() : _path(""), _phenotype(""), _ancestry(""), _algorithm("") {}
  explicit path_processor(const std::string &path)
      : _path(path), _phenotype(""), _ancestry(""), _algorithm("") {
    compute_phenotype();
    compute_ancestry();
    compute_algorithm();
  }
  path_processor(const path_processor &obj)
      : _path(obj._path),
        _phenotype(obj._phenotype),
        _ancestry(obj._ancestry),
        _algorithm(obj._algorithm) {}
  ~path_processor() throw() {}

  const std::string &get_phenotype() const { return _phenotype; }
  const std::string &get_ancestry() const { return _ancestry; }
  const std::string &get_algorithm() const { return _algorithm; }

 private:
  void compute_phenotype() { _phenotype = extract_directory(2); }
  void compute_ancestry() { _ancestry = extract_directory(1); }
  void compute_algorithm() { _algorithm = extract_directory(0); }
  std::string extract_directory(unsigned position_from_end) {
    std::vector<std::string> vec;
    splitline(_path, &vec, "/");
    if (vec.size() <= position_from_end) {
      throw std::runtime_error(
          "results path has insufficient directories "
          "to compute anaysis prefix: \"" +
          _path + "\"");
    }
    std::vector<std::string>::const_reverse_iterator iter = vec.rbegin();
    if (iter->empty()) ++iter;
    for (unsigned i = 0; i < position_from_end; ++i, ++iter) {
    }
    return *iter;
  }
  std::string _path;
  std::string _phenotype;
  std::string _ancestry;
  std::string _algorithm;
};

class info_calculator {
 public:
  info_calculator() {}
  info_calculator(const info_calculator &obj)
      : _sample_sizes(obj._sample_sizes), _rsqs(obj._rsqs) {}
  ~info_calculator() throw() {}

  void add_datapoint(unsigned sample_size, const double &rsq) {
    _sample_sizes.push_back(sample_size);
    _rsqs.push_back(rsq);
  }
  double get_weighted_average() const {
    unsigned total = 0;
    double sum = 0.0;
    for (unsigned i = 0; i < _rsqs.size(); ++i) {
      sum += _rsqs.at(i) * _sample_sizes.at(i);
      total += _sample_sizes.at(i);
    }
    if (total) {
      return sum / static_cast<double>(total);
    }
    throw std::runtime_error("info_calculator: no entries available");
  }

 private:
  std::vector<unsigned> _sample_sizes;
  std::vector<double> _rsqs;
};

void populate_info_data(const std::string &input_path, const path_processor &pp,
                        std::map<std::string, info_calculator> *target) {
  if (!target) {
    throw std::runtime_error("populate_info_data: null map pointer");
  }
  std::string line = "", chr = "", pos = "", id = "", catcher = "",
              id_chrpos = "";
  unsigned n = 0;
  double rsq = 0.0;
  std::map<std::string, info_calculator>::iterator finder;
  std::filesystem::path p(input_path);
  if (!std::filesystem::is_directory(p)) {
    throw std::runtime_error("populate_info_data: input is not directory: \"" +
                             input_path + "\"");
  }
  // for each possible imputation set, scan for the relevant analysis file
  std::vector<std::string> imputation_batches;
  imputation_batches.push_back("GSA_batch1");
  imputation_batches.push_back("GSA_batch2");
  imputation_batches.push_back("GSA_batch3");
  imputation_batches.push_back("GSA_batch4");
  imputation_batches.push_back("GSA_batch5");
  imputation_batches.push_back("Oncoarray");
  imputation_batches.push_back("OmniX");
  imputation_batches.push_back("Omni25");
  for (std::vector<std::string>::const_iterator iter =
           imputation_batches.begin();
       iter != imputation_batches.end(); ++iter) {
    std::cout << "querying imputation batch \"" << *iter << "\"" << std::endl;
    std::string filename = input_path + "/" + pp.get_phenotype() + "." + *iter +
                           "." + to_lower(pp.get_algorithm()) + ".tsv.gz";
    if (std::filesystem::is_regular_file(std::filesystem::path(filename))) {
      fileinterface::fileinterface_reader *input = 0;
      std::map<std::string, unsigned> target_variants;
      std::map<std::string, unsigned>::const_iterator query_finder;
      try {
        // extract the variants from this results file
        input = fileinterface::reconcile_reader(filename);
        input->getline(&line);
        while (input->getline(&line)) {
          std::istringstream strm1(line);
          if (!(strm1 >> chr >> pos >> id >> catcher >> catcher >> catcher >>
                catcher >> catcher >> catcher >> n))
            throw std::runtime_error("file \"" + filename +
                                     "\" unrecognized line format \"" + line +
                                     "\"");
          id_chrpos = id.find("chr") == 0
                          ? id
                          : "chr" + chr + ":" + pos + id.substr(id.find(":"));
          target_variants[id_chrpos] = n;
        }
        input->close();
        delete input;
        input = 0;
        // get raw minimac4 rsq data for these variants
        std::string info_path =
            "../../../freeze2-imputation/raw-mis-nonoverlapping-subjects/" +
            strsubst(*iter, '_', '/') + "/" + pp.get_ancestry() + "/";
        if (!std::filesystem::is_directory(std::filesystem::path(info_path))) {
          throw std::runtime_error("info path is not a directory: \"" +
                                   info_path + "\"");
        }
        for (unsigned info_chr = 1; info_chr <= 22; ++info_chr) {
          std::cout << "\t\textracting Rsq data for chromosome " << info_chr
                    << std::endl;
          std::string info_filename = info_path + "chr" +
                                      std::to_string(info_chr) +
                                      "-filtered.info.gz";
          if (!std::filesystem::is_regular_file(
                  std::filesystem::path(info_filename))) {
            throw std::runtime_error("info filename is not a regular file: \"" +
                                     info_filename + "\"");
          }
          input = fileinterface::reconcile_reader(info_filename);
          input->getline(&line);
          while (input->getline(&line)) {
            std::istringstream strm1(line);
            if (!(strm1 >> id))
              throw std::runtime_error("info file \"" + info_filename +
                                       "\" invalid id format \"" + line + "\"");
            if ((query_finder = target_variants.find(id)) ==
                target_variants.end())
              continue;
            for (unsigned i = 0; i < 5; ++i) {
              if (!(strm1 >> catcher))
                throw std::runtime_error("info file \"" + info_filename +
                                         "\" invalid data format \"" + line +
                                         "\"");
            }
            if (!(strm1 >> rsq)) {
              throw std::runtime_error("info file \"" + info_filename +
                                       "\" invalid rsq format \"" + line +
                                       "\"");
            }
            if ((finder = target->find(id)) == target->end()) {
              finder =
                  target->insert(std::make_pair(id, info_calculator())).first;
            }
            finder->second.add_datapoint(query_finder->second, rsq);
          }
          input->close();
          delete input;
          input = 0;
        }
      } catch (...) {
        if (input) delete input;
        throw;
      }
    }
  }
}

void reformat(const std::string &input_filename,
              const std::string &output_filename,
              const std::map<std::string, info_calculator> &info_data) {
  fileinterface::fileinterface_reader *input = 0;
  fileinterface::fileinterface_writer *output = 0;
  std::string line = "", chr = "", pos = "", id = "", id_chrpos = "";
  std::string effect = "", other = "", freq = "";
  std::string beta = "", se = "", p = "";
  std::string n = "", phet = "";
  std::string sep = "\t";
  double maf = 0.0;
  std::map<std::string, info_calculator>::const_iterator finder;
  try {
    input = fileinterface::reconcile_reader(input_filename);
    output = fileinterface::reconcile_writer(output_filename);
    input->getline(&line);
    output->writeline(
        "CHR\tPOS\tVCF_ID\tEFFECT_Allele\t"
        "OTHER_Allele\tEAF\tN_INFORMATIVE\t"
        "BETA\tSE\tPVALUE\tINFO\tMAC");
    while (input->getline(&line)) {
      std::istringstream strm1(line);
      if (!(strm1 >> chr >> pos >> id >> effect >> other >> freq >> beta >>
            se >> p >> n >> phet)) {
        throw std::runtime_error("format_for_psares: cannot parse file \"" +
                                 input_filename + "\" line \"" + line + "\"");
      }
      std::ostringstream o;
      maf = from_string<double>(freq);
      if (maf >= 0.5) maf = 1.0 - maf;
      unsigned mac = floor(2.0 * from_string<double>(n) * maf);
      id_chrpos = id.find("chr") == 0
                      ? id
                      : "chr" + chr + ":" + pos + id.substr(id.find(":"));
      finder = info_data.find(id_chrpos);
      if (finder == info_data.end()) {
        throw std::runtime_error(
            "format_for_psares: cannot find info information "
            "for variant \"" +
            id + "\" \"" + id_chrpos + "\" from input \"" + input_filename +
            "\"");
      }
      if (mac >= 5) {
        if (!(o << chr << sep << pos << sep << chr << ":" << pos << sep
                << effect << sep << other << sep << freq << sep << n << sep
                << beta << sep << se << sep << p << sep
                << finder->second.get_weighted_average() << sep << mac))
          throw std::runtime_error(
              "format_for_psares: cannot format output line "
              "from input \"" +
              input_filename + "\" line \"" + line + "\"");
        output->writeline(o.str());
      }
    }
    input->close();
    delete input;
    output->close();
    delete output;
  } catch (...) {
    if (input) delete input;
    if (output) delete output;
    throw;
  }
}
}  // namespace format_for_psares

int main(int argc, char **argv) {
  if (argc != 2) {
    throw std::runtime_error(
        "usage: \"format_for_psares.out input_results_path\"");
  }
  std::string date = "30nov2020";
  std::string input_results_path = std::string(argv[1]);
  format_for_psares::path_processor p(input_results_path);
  std::string phenotype = p.get_phenotype();
  std::string ancestry = p.get_ancestry();
  std::string algorithm = p.get_algorithm();
  std::string input_filename =
      input_results_path + "/" + phenotype + "." + ancestry + "." +
      format_for_psares::to_upper(algorithm) + ".tsv.gz";
  std::string output_filename = "PLCO." + phenotype + "." + ancestry +
                                ".All.GRCh38hg38.cp." + date + ".tsv.gz";
  std::map<std::string, format_for_psares::info_calculator> info_data;
  if (!std::filesystem::is_regular_file(
          std::filesystem::path(input_filename))) {
    std::cerr << "no meta-analysis file \"" << input_filename
              << "\" detected, terminating" << std::endl;
    return 0;
  }
  std::cout << "reading info data from pre-meta files" << std::endl;
  format_for_psares::populate_info_data(input_results_path, p, &info_data);
  std::cout << "reformatting input meta file to output format" << std::endl;
  format_for_psares::reformat(input_filename, output_filename, info_data);
  std::cout << "all done: " << input_filename << " -> " << output_filename
            << std::endl;
  return 0;
}
