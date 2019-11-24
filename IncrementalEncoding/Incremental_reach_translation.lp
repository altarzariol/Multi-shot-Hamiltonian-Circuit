#include <incmode>.
% Program to compute HC incrementally 
% At step t, clingo computes the Hamiltonian circuits that can be obtained with the first t nodes 


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	FIRST_STEP PROGRAM  
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for the first node: special case since we don't check acyclicity and it's reachable from the definition
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

reach(firstNode,firstNode).
#show hc/2.

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%	STEP PROGRAM
%%%%%%%%%%%%%%%%%%%%%%%%%%
% Module for adding rules concerning node t > firstNode
#program step(t).
% External atoms: in/out,reach and ws atoms for smaller nodes (X<=t) that we can encounter on the next step (t+1)
#external in(X,t+1) : node(X), X<=t.
#external out(X,t+1) : node(X), X<=t.
#external reach(X,t+1) :node (X), X<=t, X>firstNode.
#external ws(X,t+1) :node (X), X<=t, X>firstNode.

%%%%
%%%% 		CREATE HC ATOMS
%%%%

% We can add a new outgoing or incoming edge for node t from a node that has been already considered (i.e. Y<t)  
{hc(t,Y)} :- edge(t,Y), Y<t.
{hc(Y,t)} :- edge(Y,t), Y<t.

%%%%
%%%% 		OUT ATOMS
%%%%

% The meaning of out(X,Y) is that node X has an outgoing edge to node Y (first and third rules). To cope with incremental encoding,
%    this atom is propagated\linearized for all nodes smaller than Y (second and fourth rules).

% The atoms out(t,Y) is obtained if we have an outgoing edge from t to Y (with Y<t)
out(t,Y) :- hc(t,Y), Y<t.
% or if we have already deduced the atoms out(t,Y+1) and we linearize the property until the firstNode.
%    Note: out(t,t+1) is defined as external.
out(t,Y-1) :- out(t,Y), Y>firstNode.

% The atoms out(Y,t) is obtained if we have an outgoing edge from Y to t (with Y<t)
out(Y,t) :- hc(Y,t), Y<t.
% or if in the next steps we will find out(Y,t+1) 
%    (we define this rule in order to propagate the property/predicate "out" of node Y) 
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

% The atoms in(t,Y) is obtained if we have an incoming edge from t to Y (with Y<t)
in(t,Y) :- hc(Y,t), Y<t.
% or if we have already deduced the atoms in(t,Y+1) and we linearize the property until the firstNode.
%    Note: in(t,t+1) is defined as external.
in(t,Y-1) :- in(t,Y), Y>firstNode.

% The atoms in(Y,t) is obtained if we have an incoming edge from t to Y (with Y<t) 
in(Y,t) :- hc(t,Y), Y<t.
% or if in the next steps we will find in(Y,t+1) 
%    (we define this rule in order to propagate the property/predicate "in" of node Y) 
in(Y,t) :- in(Y,t+1), Y<t.

% Condition to force that there is at most one incoming edge in the circuit for node t: 
%    we can't have an incoming edge (hc(Y,t)) as well as in(t,Y+1) (which is deduced if there exist another incoming edge hc(X,t) with X > Y)
:- hc(Y,t), in(t,Y+1).
% The same constraint is propagated for the node Y<t
:- hc(t,Y), in(Y,t+1), Y<t.

% Condition to force that there exists at least one incoming edge in the circuit for node t
:- node(t), not in(t,firstNode).

%%%%
%%%% 		ACYCLICITY CHECKING: REACHABLE AND WELL-SUPPORTED
%%%%

% Rules that allow reachability checking in the resulting Hamiltonian Cycle 
% We say that a node n is reachable if the atom reach(n,firstNode) holds.
%    To obtain that atom, we write a series of rules that propagate the reachability property (similarly to out and in):
%    The rules "reach(n,n) :- reach(n,n+1)." ... "reach(n,firstNode) :- reach(n,firstNode+1)."} are defined when n=t
%    "reach(n,t) :- reach(n,t+1)." at step t, when t > n   

% reach(t,Y) (with Y<t) holds if:
%    Y is directly connected to t and Y is reachable from the first node
reach(t,Y) :- hc(Y,t), reach(Y,firstNode), t !=Y.
%    or if we have already deduced the atoms reach(t,Y+1)
reach(t,Y) :- reach(t,Y+1), Y>=firstNode.
%    Note: as reach(t,t+1) is defined as external, the rules {"reach(t,t) :- reach(t,t+1)." ... "reach(t,firstNode) :- reach(t,firstNode+1)."} 
%          are instantiated in this step, thus whenever t will be reachable from a bigger node 
%          the rules will propagate obtaining reach(t,firstNode)

% reach(Y,t) (with Y<t) holds if t is directly connected to Y and t is reachable from the first node
reach(Y,t) :- hc(t,Y), reach(t,firstNode), t !=Y, Y != firstNode.
% or if in the next steps we will find reach(Y,t+1) 
%    (we define this rule in order to propagate the property/predicate "reach" of node Y) 
reach(Y,t) :- reach(Y,t+1).

% the node t should be reachable
:- node(t), not reach(t,firstNode).

%%%%%%%%%%%%%
% Rules inspired by the paper: "Answer Set Programming modulo Acyclicity"
%%%%%%%%%%%%%

% Define the dependency graph for all hc arcs (except the starting node)
{dep(t,X)} :- reach(X,firstNode), hc(X,t), X !=firstNode.
{dep(X,t)} :- reach(t,firstNode), hc(t,X), X !=firstNode.

% The dependency graph must be acyclic
#edge(t,X) : dep(t,X).
#edge(X,t) : dep(X,t).


% Node t has a well-supported rule for reachability if:
%   t is directly connected from the firstNode
ws(t,firstNode) :- hc(firstNode,t).
%   t is directly connected to node X (X<t) and t depends on node X (which is reachable for definition of the predicate dep) 
ws(t,X) :- dep(t,X), hc(X,t).
%   or if we have already deduced the atoms ws(t,X+1) and we linearize the property until the firstNode.
%    Note: ws(t,t+1) is defined as external.
ws(t,X) :- ws(t,X+1),X >=firstNode. 


% Node X (X<t) has a well-supported rule for reachability if:
%   X is directly connected to node t and X depends on node t
ws(X,t) :- dep(X,t), hc(t,X).
% or if in the next steps we will find ws(X,t+1) 
%    (we define this rule in order to propagate the property/predicate "ws" of node X) 
ws(X,t) :- ws(X,t+1). 

% If a node is reachable, it should also be well-defined 
:- reach(t,firstNode), not ws(t,firstNode).

#show hc/2. 