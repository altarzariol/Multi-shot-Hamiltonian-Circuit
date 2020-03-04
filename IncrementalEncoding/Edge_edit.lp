#include <incmode>.
% Program to compute HC incrementally using just the directive edge
% At step t, clingo computes the Hamiltonian circuits that can be obtained with the first t nodes 



%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	FIRST_STEP PROGRAM  
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for the first node: special case since we don't check acyclicity
#program first_step(firstNode).

#external out(firstNode,firstNode).
#external in(firstNode,firstNode).

%Base case
aux_out(firstNode,firstNode,1).
aux_in(firstNode,firstNode,1).

{hc(firstNode,firstNode)} :- edge(firstNode,firstNode).

:- not hc(firstNode,firstNode), not out(firstNode,firstNode).
:- not hc(firstNode,firstNode), not in(firstNode,firstNode).
% :- hc(firstNode,firstNode), out(firstNode,firstNode). % introduced "too" early

#show hc/2.
%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	STEP PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for adding rules concerning node t > firstNode
#program step(t).
% External atoms: in/out(X,t) new externals (at time t) for all smaller nodes that are connected to node t
#external out(X,t) : edge(X,t), X < t.
#external in(X,t) : edge(t,X), X < t.
% External for node t
#external out(t,Y) : last_out(Y,t).
#external in(t,Y) : last_in(Y,t).

% bigger (in [1...t-1]) incoming and outgoing node for t (1 if not connected)
last_out(Y,t) :- Y = #max{1; X : edge(t,X), X < t}.
last_in(Y,t) :- Y = #max{1; X : edge(X,t), X < t}.

% auxiliary predicates for time t:  
%  aux_out/in(X,Y,t) ---> Y is the bigger node in [1..t] connected(out/in) to t
aux_out(t,Y,t) :- last_out(Y,t).
aux_out(X,t,t) :- edge(X,t), X < t.
aux_out(X,Y,t) :- aux_out(X,Y,t-1), not edge(X,t).

aux_in(t,Y,t) :- last_in(Y,t).
aux_in(X,t,t) :- edge(t,X), X < t.
aux_in(X,Y,t) :- aux_in(X,Y,t-1), not edge(t,X).

% We can add a new outgoing or incoming edge for node t from a node that has been already considered (i.e. Y<t)  
{hc(t,Y)} :- edge(t,Y), Y<t.
{hc(X,t)} :- edge(X,t), X<t.

% if X has one outgoing edge (in the circuit) to t, then the external instantiated previously (time Y) becomes true.
out(X,Y) :- aux_out(X,Y,t-1), hc(X,t).
% otherwise is propagated
%  NOTE: t is the biggest outgoing edge for X, the previous external will depend to out(X,t) 
out(X,Y) :- aux_out(X,Y,t-1), out(X,t).

% Constraint for having at most one outgoing edge for node X:
% It's impossible that I've an edge in the circuit from a X to Y (hc(X,Y)) and also an edge from X to a node bigger that Y (out(X,Y))
:- aux_out(X,Y,t-1), hc(X,Y), out(X,Y), edge(X,t).


% Chain of "local" predicates that are propagated till 1 
out(t,Y-1) :- hc(t,Y), 1 < Y.
out(t,Y-1) :- out(t,Y), 1 < Y.

% Constraint for having at least one outgoing edge for node X:
:- not hc(t,1), not out(t,1).

:- hc(t,Y), out(t,Y), not last_out(Y,t).
%Same reasoning for incoming edge

in(X,Y) :- aux_in(X,Y,t-1), hc(t,X).
in(X,Y) :- aux_in(X,Y,t-1), in(X,t).

:- aux_in(X,Y,t-1), hc(Y,X), in(X,Y), edge(t,X).

in(t,Y-1) :- hc(Y,t), 1 < Y.
in(t,Y-1) :- in(t,Y), 1 < Y.

:- not hc(1,t), not in(t,1).

:- hc(Y,t), in(t,Y), not last_in(Y,t).


%%%%
%%%% 		OUT ATOMS
%%%%
#edge(X,t) : hc(X,t), X != firstNode.
#edge(t,X) : hc(t,X), X != firstNode.
