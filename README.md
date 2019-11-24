# Multi-shot-Hamiltonian-Circuit
We address the **Hamiltonian Circuit (HC)** problem, using Anser Set Programming. Our aim is comparing multi-shot encodings with the equivalent one-shot versions and the baseline (with aggregates).

## Parsing input files
 -  OriginalInput/         - original input files (graphs that may have missing nodes)
 -  parse.lp               - logic program for parsing the input graphs
 -  converInput            - script to nomalize all the original input graphs using parse.lp
   
## Encodings 
 -  runTests               - run all the encodings (in total six versions) for each input file and create the csv file
 -  main.py                - python script that control the ground for each encoding and collect the data after the solving
 -  BaselineEncoding/      - standard encodings that use the aggregate rules
 -  IncrementalEncoding/   - multi-shot encodings that linearize the rules from the baseline programs
