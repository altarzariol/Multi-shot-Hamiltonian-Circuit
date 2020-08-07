%%%%%%%%%
%% Logic program to normalize input graphs (consecutive nodes)
%%%%%%%%%
edge(Y,X) :- edge(X,Y).

#show.
#show node/1.
#show edge/2.
#show z(N) : N = #count{M : node(M)}.

% echo "#const firstNode = 1."; clingo parse.lp Input/TSP/test.asp --outf=1 | grep -A1 ANSWER | tail -n1 | tr ' ' '\n' | sort -t"(" -k1,1r -k2,2 | sed 's/z(\(.*\))\./#const maxNode = \1./'

