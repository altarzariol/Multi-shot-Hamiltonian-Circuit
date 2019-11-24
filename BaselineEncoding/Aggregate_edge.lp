%%%%
% Standard Encoding with directive "#edge" to check acyclicity
%%%%

%#const currentNode = #sup.

% the auxiliary predicates, node' and edge', allow for defining the rules up to the current node considered
#program step(currentNode).

node'(X) :- node(X), firstNode <= X, X <= currentNode.
edge'(X,Y) :- edge(X,Y), node'(X), node'(Y).

1 {hc(X,Y) : edge'(X,Y)} 1 :- node'(X).
1 {hc(X,Y) : edge'(X,Y)} 1 :- node'(Y).

#edge(X,Y) : hc(X,Y), X != firstNode, Y != firstNode.

#show hc/2.
