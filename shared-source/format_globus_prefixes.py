#!/usr/bin/env python3
import sys
import yaml
x = yaml.safe_load(open(sys.argv[1]))
if (x.get('exclude_from_atlas') is None):
    pheno = x.get('phenotype')


    algo = x.get('algorithm')
    if (isinstance(algo, str)):
        if algo == "boltlmm" or algo == "saige":
            print(pheno, algo.upper(), sep=".")
    elif (isinstance(algo, list)):
        for val in algo:
            print (val)
            if val == "boltlmm" or val == "saige":
                print(pheno, val.upper(), sep=".")
