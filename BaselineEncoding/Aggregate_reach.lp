%%%%
% Standard Encoding with predicate reach 
%%%%

% the auxiliary predicates, node' and edge', allow for defining the rules up to the current node considered
#program step(currentNode).

node'(X) :- node(X), firstNode <= X, X <= currentNode.
edge'(X,Y) :- edge(X,Y), node'(X), node'(Y).

1 {hc(X,Y) : edge'(X,Y)} 1 :- node'(X).
1 {hc(X,Y) : edge'(X,Y)} 1 :- node'(Y).

reach(firstNode) :- node'(firstNode).
reach(Y) :- reach(X), hc(X,Y), Y != firstNode.
:- node'(X), not reach(X).

#show hc/2.
