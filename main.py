#!/usr/bin/env python3

import clingo
import json
import sys
import argparse
import csv
import os
import ntpath
from pandas import DataFrame
from pathlib import Path

CSV_FILE_NAME = str(Path().absolute())

class App:
    def __init__(self, args):
        self.control = clingo.Control()
        self.args = args
        # number of nodes considered until now 
        self.nodes = 0
        # smaller node in the input graph
        self.firstNode = 0
        # max node in the input graph
        self.maxNode = 0
        # total grounding time: in the incremental mode, it is the grounding time of the last call, while 
        # for the standard encode, it sums the current grounding time to the previous
        self.groundTotalTime = 0
        # total solving time: in the incremental mode, it is the solving time of the last call, while 
        # for the standard encode, it sums the current solve time to the previous
        self.solvingTotalTime = 0

    def show(self, model):
        # print the solution found (if the running script doesn't contains the option --quiet)
        if not self.args.quiet:
            print("Hamiltonian circuit: {}".format(model))

    def ground(self):
        # parts = lists containing the modules to ground
        parts = []
        if self.args.baseline:
        	# in baseline encoding
            self.control = clingo.Control()
                # reload the inputs files
            for source in self.args.file: 
                self.control.load(source)
            parts.append(("base", []))
            parts.append(("step", [self.nodes]))
        else: 
            # if we are considering the standard encoding mode AND it is not the first iteration
            if self.args.scratch and self.nodes > self.firstNode:
                self.control = clingo.Control()
                # reload the inputs files
                for source in self.args.file: 
                    self.control.load(source)
                # add the modules "step" to the list parts for all the nodes from firstNode+1 up to the last node considered 
                for i in range(self.firstNode, self.nodes): 
                    parts.append(("step", [i+1]))

            # if we are considering the standard encoding OR we are on the first iteration
            if self.args.scratch or self.nodes == self.firstNode:
                # add the base module, which only consists of the input file
                parts.append(("base", []))
                # and the first_step module that considers just the first node
                parts.append(("first_step", [self.firstNode]))
            else:
                # otherwise (after the first step, in incremental mode) add the module that consider the last node
                parts.append(("step", [self.nodes]))

        # print the last node considered (if the running script contains the option --verbose)
        if self.args.verbose:
             print("")
             print("Last node considered: {}".format(self.nodes))
        
        # ground all the modules in parts 
        self.control.ground(parts)

    def run(self):
        # load the input files and define the values maxNode, firstNode and nodes 
        for source in self.args.file:
            self.control.load(source)
        self.maxNode = self.control.get_const("maxNode").number
        self.firstNode = self.control.get_const("firstNode").number
        self.nodes = self.control.get_const("firstNode").number 
        # iterates until reaching the last node in the input graph
        while self.nodes <= self.maxNode:
            self.ground()
            #ret = self.control.solve(on_model=self.show)
            with self.control.solve(on_model=self.show, async_=True) as handle:
                wait = handle.wait(60)
                handle.cancel()
                ret = handle.get()
            # create a csv file with statistics (if the running script contains the option --stats)
            if self.args.stats:
                    # update the attribute solvingTotalTime and groundTotalTime, according to the mode considered
                    if self.args.scratch or self.args.baseline:
                        # standard
                        self.solvingTotalTime += self.control.statistics['summary']['times']['solve']
                        self.groundTotalTime += (self.control.statistics['summary']['times']['total'] - self.control.statistics['summary']['times']['solve'])
                    else:
                        # incremental 
                        self.solvingTotalTime = self.control.statistics['summary']['times']['solve']
                        self.groundTotalTime = (self.control.statistics['summary']['times']['total'] - self.control.statistics['summary']['times']['solve'])
                    # define a dictionary containing the statistics of the last solving call
                    stats = { \
                    'inputFile' :ntpath.basename(self.args.file[0]), \
                    'encodingFile' : ntpath.basename(self.args.file[1]), \
                    'last node':self.nodes, \
                    'max node':self.maxNode, \
                    'satisfiable': 'Timeout' if (not wait) else ret.satisfiable, \
                    'mode':'Standard' if (self.args.scratch or self.args.baseline) else 'Incremental', \
                    'groundTotalTime' : self.groundTotalTime, \
                    'solvingTotalTime' : self.solvingTotalTime, \
                    'groundAndSolvingTotalTime' : self.groundTotalTime + self.solvingTotalTime
                    }
                    for x in self.control.statistics['problem']['generator']:
                        stats[x] = self.control.statistics['problem']['generator'][x]
                    for x in self.control.statistics['solving']['solvers']:
                        stats[x] = self.control.statistics['solving']['solvers'][x]
                    for x in self.control.statistics['summary']['times']:
                        stats[x] = self.control.statistics['summary']['times'][x]
                    stats['ground'] = self.control.statistics['summary']['times']['total'] - self.control.statistics['summary']['times']['solve']
                    # create a dataframe using stats
                    df = DataFrame(data=stats, index={self.args.instanceNumber[0]})
                    header=list(stats.keys())
                    # create the csv file if it doesn't exist, defining the headers
                    fileName=CSV_FILE_NAME+'/'+stats['mode']+'_'+ntpath.basename(self.args.file[1])+'.csv'
                    if not os.path.isfile(fileName):
                        df.to_csv(fileName, header=header)
                    # otherwise, just append the new row
                    else:
                        df.to_csv(fileName, mode='a', header=False)
            # update the number of nodes for the next call 
            self.nodes += 1

#main code
parser = argparse.ArgumentParser(description="Gradually expand logic programs.", epilog="""Example: main.py -b -x -q -s -v instance.lp encoding.lp""")

parser.add_argument("-b", "--baseline", action='store_true', help="baseline encoding")
parser.add_argument("-x", "--scratch", action='store_true', help="start each step from scratch (single-shot solving)")
parser.add_argument("-q", "--quiet", action='store_true', help="do not print models")
parser.add_argument("-s", "--stats", action='store_true', help="print solver statistics")
parser.add_argument("-v", "--verbose", action='store_true', help="print progress information")
parser.add_argument("-i", "--instanceNumber", nargs=1, metavar=("NUM"), help="number of input instance")
parser.add_argument("file", nargs="*", default=[], help="gringo source files")

args = parser.parse_args()
# run the application with the parsed args
App(args).run() 
