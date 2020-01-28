import re
import numpy as np
import os
# Open files from current dir
directoryName = "Processed_Input\\NewInput"
for filename in os.listdir(os.getcwd() + "\\" + directoryName):
# Create Adjacency matrix
	with open(directoryName+"\\"+filename) as f:
		print(filename)
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
# Calculate scores
	# Outgoing edge for all nodes
	outAll = Matrix.sum(axis=1)
	# ingoing edge for all nodes
	inAll = Matrix.sum(axis=0)

	# Redefine nodes order according to the scores: from i=0 to maxnode-1
	for i in range(maxnode):
		# Outgoing edge for smaller nodes
		outSmall = Matrix[:,:i].sum(axis=1)
		# Incoming edge for smaller nodes
		inSmall =  Matrix[:i,:].sum(axis=0)
		score1 = np.minimum(outSmall, inSmall)
		score2 = np.maximum(outSmall, inSmall)
		score3 = np.minimum(outAll, inAll)
		score4 = np.maximum(outAll, inAll)
		# I cannot reorder the nodes smaller than i
		score1[:i] = -1
		score2[:i] = -1
		score3[:i] = -1
		score4[:i] = -1
		# Best nodes according to score1
		bests = np.argwhere(score1 == np.amax(score1))
		firstMax = bests.flatten().tolist()
		# Check tie
		if len(firstMax) == 1:
			selNode = firstMax[0]
		else:
			# Do not consider the nodes that don't appear in firstMax
			for j in range(maxnode):
				if j not in firstMax:
					score2[j] = -1
			# Best nodes according to score1 >> score2
			bests = np.argwhere(score2 == np.amax(score2))
			firstMax = bests.flatten().tolist()
			# Check tie
			if len(firstMax) == 1:
				selNode = firstMax[0]
			else:
				# Do not consider the nodes that don't appear in firstMax
				for j in range(maxnode):
					if j not in firstMax:
						score3[j] = -1
				# Best nodes according to score1 >> score2 >> score3
				bests = np.argwhere(score3 == np.amax(score3))
				firstMax = bests.flatten().tolist()
				# Check tie
				if len(firstMax) == 1:
					selNode = firstMax[0]
				else:
					# Do not consider the nodes that don't appear in firstMax
					for j in range(maxnode):
						if j not in firstMax:
							score4[j] = -1
					# Best nodes according to score1 >> score2 >> score3 >> score4		
					bests = np.argwhere(score4 == np.amax(score4))
					firstMax = bests.flatten().tolist()
					# If tie, take the smaller node
					selNode = firstMax[0]
		#Swap the coloum and row between the current node and the selected one
		Matrix[:,[i, selNode]] = Matrix[:,[selNode, i]]
		Matrix[[i, selNode],:] = Matrix[[selNode, i],:]
		#Recalculate score3 and score4
		outAll = Matrix.sum(axis=1)
		inAll = Matrix.sum(axis=0)
		score3 = np.minimum(outAll, inAll)
		score4 = np.maximum(outAll, inAll)
		#print(Matrix)
# Create new file
	newFile = os.getcwd() + "\\Reorder_Input\\"+directoryName+ "\\" + os.path.basename(filename)
	with open(newFile, 'a') as file:
		file.write('#const firstNode = 1.\n#const maxNode = '+str(maxnode)+'.\n')
		for i in range(maxnode):
			file.write('node('+str(i+1)+').\n')
		for i in range(maxnode):
			for j in range(maxnode):
				if Matrix[[i],[j]]==1:
	 				file.write('edge('+str(i+1)+','+str(j+1)+').\n')