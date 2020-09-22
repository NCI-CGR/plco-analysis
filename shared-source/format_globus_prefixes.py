#!/usr/bin/env python3
import sys
import yaml
x = yaml.safe_load(open(sys.argv[1]))
if (x.get('exclude_from_atlas') is None):
    pheno = x.get('phenotype')
    for val in x.get('algorithm'):
        if val == "boltlmm" or val == "saige":
            print(pheno, val.upper(), sep=".")
