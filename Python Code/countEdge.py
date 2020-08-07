from __future__ import division
import re
import numpy as np
import os
import pandas as pd
from pandas import DataFrame
# Open files from current dir
directory = "/CSV Files/Reorderd Test"
print(directory)
list = os.listdir(directory)
pairs = []
for file in list:
    location = os.path.join(directory, file)
    size = os.path.getsize(location)
    pairs.append((size, file))
pairs.sort(key=lambda s: -s[0])

NumOfEdgesTot = []
Namefile = []
indexTot = []
instanceNum = 1
for pair in pairs:
	if pair[1] != '.directory':
		with open(directory+"/"+pair[1]) as f:
			print(pair[1])
			# parse maxnode
			head = [next(f) for x in range(2)]
			match=re.split(r'maxNode = ', head[1])
			maxnode = int(match[1].replace(".", ""))
			# define the matrix: maxnode*maxnode
			Matrix = np.zeros(shape=(maxnode,maxnode))
			for line in f:
				if re.search(r'edge', line):
					m = re.split('\(|,|\)',line)
					Matrix[int(m[1])-1][int(m[2])-1]=1
		NumOfEdges = []
		Namefil = []
		index = []
		# Calculate edges
		for i in range(1,maxnode+1):
			count = Matrix[:i,:i].sum()
			NumOfEdges.append(count)
			Namefil.append(pair[1])
			index.append(instanceNum)
		Namefile.extend(Namefil*8)
		NumOfEdgesTot.extend(NumOfEdges*8)
		indexTot.extend(index*8)
		instanceNum= instanceNum+1
data = {'NumOfEdges' : NumOfEdgesTot, 'NumOfInstance' : indexTot}
df = DataFrame(data=data)
df2 = pd.read_csv("NewInput_DataOutput.csv")
df2['NumOfEdges'] = df['NumOfEdges']
df2.to_csv('Alice.csv')