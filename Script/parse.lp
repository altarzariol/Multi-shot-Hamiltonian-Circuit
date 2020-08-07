%%%%%%%%%
%% Logic program to normalize input graphs (consecutive nodes)
%%%%%%%%%
map(N,M) :- node(N), M = #count{NN : node(NN), NN <= N}.

#show.
#show node(M) : map(N,M).
#show edge(M,N) : edge(X,Y), map(X,M), map(Y,N).
#show z(N) : N = #count{M : node(M)}.

% echo "#const firstNode = 1."; clingo parse.lp Input/TSP/test.asp --outf=1 | grep -A1 ANSWER | tail -n1 | tr ' ' '\n' | sort -t"(" -k1,1r -k2,2 | sed 's/z(\(.*\))\./#const maxNode = \1./'

