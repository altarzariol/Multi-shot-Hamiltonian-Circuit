#include <incmode>.
% Program to compute HC incrementally using just the directive edge
% At step t, clingo computes the Hamiltonian circuits that can be obtained with the first t nodes 



%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	FIRST_STEP PROGRAM  
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for the first node: special case since we don't check acyclicity
#program first_step(firstNode).
#external in(firstNode,firstNode+1).
#external out(firstNode,firstNode+1).

{hc(firstNode,firstNode)} :- edge(firstNode,firstNode).

out(firstNode,firstNode) :- hc(firstNode,firstNode).
out(firstNode,firstNode) :- out(firstNode,firstNode+1).
:- hc(firstNode,firstNode), out(firstNode,firstNode+1).

in(firstNode,firstNode) :- hc(firstNode,firstNode).
in(firstNode,firstNode) :- in(firstNode,firstNode+1).
:- hc(firstNode,firstNode), in(firstNode,firstNode+1).

:- node(firstNode), not out(firstNode,firstNode).
:- node(firstNode), not in(firstNode,firstNode).

#show hc/2.


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	STEP PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for adding rules concerning node t > firstNode
#program step(t).
% External atoms: in/out atoms for smaller nodes (X<=t) that we can encounter on the next step (t+1)
#external in(X,t+1) : node(X), X<=t.
#external out(X,t+1) : node(X), X<=t.

%%%%
%%%% 		CREATE HC ATOMS
%%%%

% We can add a new outgoing or incoming edge for node t from a node that has been already considered (i.e. Y<t)  
{hc(t,Y)} :- edge(t,Y), Y<t.
{hc(Y,t)} :- edge(Y,t), Y<t.

%%%%
%%%% 		OUT ATOMS
%%%%

% Same definition contained in Incremental_reach_translation.lp
out(t,Y) :- hc(t,Y), Y<t.
out(t,Y-1) :- out(t,Y), Y>firstNode.

out(Y,t) :- hc(Y,t), Y<t.
out(Y,t) :- out(Y,t+1), Y<t.

% Condition to force that there is at most one outgoing edge in the circuit for node t: 
%    we can't have an outgoing edge (hc(t,Y)) as well as out(t,Y+1) (which is deduced if there exist another outgoing edge hc(t,X) with X > Y)
:- hc(t,Y), out(t,Y+1).
% The same constraint is propagated for the node Y<t
:- hc(Y,t), out(Y,t+1), Y<t.

% Condition to force that there exists at least one outgoing edge in the circuit for node t
:- node(t), not out(t,firstNode).

%%%%
%%%% 		IN ATOMS
%%%%

% Same reasoning of outgoping edge for incoming edge
in(t,Y) :- hc(Y,t), Y<t.
in(t,Y-1) :- in(t,Y), Y>firstNode.

in(Y,t) :- hc(t,Y), Y<t.
in(Y,t) :- in(Y,t+1), Y<t.

% Condition to force that there is at most one incoming edge in the circuit for node t: 
%    we can't have an incoming edge (hc(Y,t)) as well as in(t,Y+1) (which is deduced if there exist another incoming edge hc(X,t) with X > Y)
:- hc(Y,t), in(t,Y+1).
% The same constraint is propagated for the node Y<t
:- hc(t,Y), in(Y,t+1), Y<t.

% Condition to force that there exists at least one incoming edge in the circuit for node t
:- node(t), not in(t,firstNode).

%%%%
%%%% 		ACYCLICITY CHECKING: DIRECTIVE EDGE
%%%%
#edge(X,t) : hc(X,t), X != firstNode.
#edge(t,X) : hc(t,X), X != firstNode.

#show hc/2. 
