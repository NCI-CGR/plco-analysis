/*!
  \file cargs.cc
  \brief method implementation for command line argument parser class
*/

#include "qsub_job_monitor/cargs.h"

void qsub_job_monitor::cargs::initialize_options() {
  _desc.add_options()
    ("help,h", "emit this help message")
    ("output-prefix,o", boost::program_options::value<std::string>(), "prefix of all qsub output files")
    ("job-name,j", boost::program_options::value<std::string>()->default_value(""), "name of submitted job (optional)")
    ("resources,r", boost::program_options::value<std::string>()->default_value("h_rt=2:00:00"), "resource request to qsub")
    ("queue,q", boost::program_options::value<std::string>()->default_value("all.q"), "qsub queue")
    ("command-script,c", boost::program_options::value<std::string>(), "name of script to run")
    ("sleep-time,t", boost::program_options::value<unsigned>()->default_value(10), "number of seconds to sleep between checks")
    ("crashcheck-interval,i", boost::program_options::value<unsigned>()->default_value(3600), "number of seconds to wait before checking queue for job existence")
    ("crashcheck-attempts,a", boost::program_options::value<unsigned>()->default_value(10), "number of times to attempt qstat before killing process")
    ;
}
