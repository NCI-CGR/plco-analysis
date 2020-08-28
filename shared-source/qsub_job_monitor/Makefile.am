bin_PROGRAMS = qsub_job_monitor.out
qsub_job_monitor_out_SOURCES = qsub_job_monitor/cargs.cc qsub_job_monitor/cargs.h qsub_job_monitor/main.cc qsub_job_monitor/utilities.cc qsub_job_monitor/utilities.h
qsub_job_monitor_out_CXXFLAGS = $(BOOST_CPPFLAGS) -ggdb -Wall -std=c++17 -static
qsub_job_monitor_out_LDADD = -lstdc++fs
qsub_job_monitor_out_LDFLAGS = -L/home/palmercd/Development/stage/lib /home/palmercd/Development/stage/lib/libboost_program_options.a
## EXTRA_DIST = examples
#qsub_job_monitordir = $(prefix)/@PACKAGE@/examples
#qsub_job_monitor_DATA = examples/example.sh examples/mi.imputeddataset.config examples/mi.program.config examples/mi.queue.config examples/test.gen examples/test.sample
dist_doc_DATA = README
ACLOCAL_AMFLAGS = -I m4
