#include <string>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <map>
#include <utility>
#include <stdexcept>
#include <filesystem>
#include <ctime>

#include "qsub_job_monitor/cargs.h"
#include "qsub_job_monitor/utilities.h"

using namespace qsub_job_monitor;

int main(int argc, char **argv) {
  cargs ap(argc, argv);
  if (ap.help() || argc == 1) {
    ap.print_help(std::cout);
    return 1;
  }
  std::string logging_prefix = ap.get_output_prefix();
  std::string resources = ap.get_resources();
  std::string qsub_queue = ap.get_queue();
  std::string command_script = ap.get_command_script();
  std::string job_name = ap.get_job_name();
  if (job_name.empty()) {
    if (logging_prefix.rfind("/") != std::string::npos) {
      job_name = logging_prefix.substr(logging_prefix.rfind("/") + 1);
    } else {
      job_name = logging_prefix;
    }
  }
  // for reasons, the job name can't start with a digit
  job_name = job_name.substr(job_name.find_first_not_of("0123456789"));
  if (job_name.empty()) job_name = "bash";
  unsigned sleep_in_seconds = ap.get_sleep_time();
  unsigned crashcheck_interval_in_seconds = ap.get_crashcheck_interval();
  unsigned crashcheck_attempts = ap.get_crashcheck_attempts();
  std::string qsub_command = "qsub -N " + job_name + " -o " + logging_prefix + ".output -e " + logging_prefix + ".error -V -q " + qsub_queue + " -l " + resources + " -cwd -S /bin/bash -b y bash " + command_script;
  std::string qsub_screen_output = "";
  std::time_t my_time;
  my_time = std::time(NULL);
  std::cout << "start: " << std::asctime(std::localtime(&my_time)) << std::endl;
  // if this is running, we've made it through a dependency tracker. So any existing success or fail indicator file should be purged
  if (std::filesystem::exists(logging_prefix + ".success")) {
    std::filesystem::remove(logging_prefix + ".success");
  }
  if (std::filesystem::exists(logging_prefix + ".fail")) {
    std::filesystem::remove(logging_prefix + ".fail");
  }
  if (exec(qsub_command, qsub_screen_output)) {
    throw std::runtime_error("unable to execute qsub command: \"" + qsub_command + "\"");
  }
  std::cout << qsub_screen_output << std::endl;
  unsigned job_id = get_job_id(qsub_screen_output);
  unsigned seconds_elapsed_since_crashcheck = 0;
  while (true) {
    if (std::filesystem::exists(logging_prefix + ".success")) {
      my_time = std::time(NULL);
      std::cout << "end (standard): " << std::asctime(std::localtime(&my_time)) << std::endl;
      return 0;
    } else if (std::filesystem::exists(logging_prefix + ".fail")) {
      return 2;
    } else {
      sleep(sleep_in_seconds);
    }
    seconds_elapsed_since_crashcheck += sleep_in_seconds;
    // after a certain interval has elapsed, check to be sure the job still exists, and die if not
    if (seconds_elapsed_since_crashcheck >= crashcheck_interval_in_seconds) {
      std::string qstat_log = "";
      std::map<unsigned, bool> current_job_ids;
      unsigned n_crashcheck_retries = 0;
      for ( ; n_crashcheck_retries < crashcheck_attempts; ++n_crashcheck_retries) {
	if (exec("qstat", qstat_log)) {
	  // wait a while, schedulers tend to have intermittent access issues
	  sleep(60);
	} else {
	  // parse the output into active job ids
	  get_job_ids(qstat_log, current_job_ids);
	  if (current_job_ids.find(job_id) != current_job_ids.end()) {
	    break;
	  } else {
	    // there is a minor possibility that the job finished between when we started the crashcheck and now. check that
	    if (std::filesystem::exists(logging_prefix + ".success")) {
	      my_time = std::time(NULL);
	      std::cout << "end (within crashcheck): " << std::asctime(std::localtime(&my_time)) << std::endl;
	      return 0;
	    } else if (std::filesystem::exists(logging_prefix + ".fail")) {
	      return 2;
	    } else {
	      // note that there is some degree of desync between jobs finishing and tracking files becoming available
	      // there isn't a perfect general purpose solution to this problem...
	      std::cout << "warning: job \"" << qsub_command << "\" (id " << job_id
			<< ") is missing from queue but tracking files have not been written. this is possibly due to filesystem desync..."
		" waiting to see if the file becomes available" << std::endl;
	      sleep(120);
	      if (std::filesystem::exists(logging_prefix + ".success")) {
		std::cout << "resolution: job \"" << qsub_command << "\" (id " << job_id << ") resolved missing tracking files by having success appear, exiting normally" << std::endl;
		my_time = std::time(NULL);
		std::cout << "end (within crashcheck): " << std::asctime(std::localtime(&my_time)) << std::endl;
		return 0;
	      } else if (std::filesystem::exists(logging_prefix + ".fail")) {
		std::cout << "resolution: job \"" << qsub_command << "\" (id " << job_id
			  << ") resolved missing tracking files by having fail appear, exiting normally (though in failure)" << std::endl;
		return 2;
	      } else { // it crashed without indicating why. resub
		std::cout << "WARNING: job \"" << qsub_command << "\" (id " << job_id << ") has detected crash, auto-resubmitting" << std::endl;
		if (exec(qsub_command, qsub_screen_output)) {
		  throw std::runtime_error("unable to relaunch qsub command: \"" + qsub_command + "\"");
		}
		std::cout << "echoed output: " << qsub_screen_output << std::endl;
		job_id = get_job_id(qsub_screen_output);
		seconds_elapsed_since_crashcheck = 0;
		break;
	      }
	    }
	  }
	}
      }
      if (n_crashcheck_retries >= crashcheck_attempts) {
	throw std::runtime_error("in crashcheck, failed qstat attempts exceeded acceptable threshold");
      }
    }
  }
}
