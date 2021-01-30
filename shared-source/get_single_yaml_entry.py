#!/usr/bin/env python3
import sys
import yaml
data = yaml.safe_load(open(sys.argv[1]))
for x in range(len(sys.argv) - 2):
    data = data.get(sys.argv[x + 2])
print(data)
