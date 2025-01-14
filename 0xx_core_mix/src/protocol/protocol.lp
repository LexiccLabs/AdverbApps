%
% There are two parts in this model:
% 
% 1) Execution: specified at the single trustee level to serve as the 
% execution logic for each mixnet node
%
% 2) Simulation: specified at the trustee group level to simulate joint
% execution of all trustee nodes, each executing the protocol individually 
% as defined in Execution.
%

%*******************************************************************************%
%******************************** EXECUTION ************************************%
%*******************************************************************************%

%**************** Action predicates ****************%

do(act_sign_config(ConfigHash), A, T) :-
	posted(config(ConfigHash, _, _, SelfT, A), T),
	not posted(config_signature(ConfigHash, A), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_post_share(ConfigHash, Contest), A, T) :-
    posted(config(ConfigHash, _, _, SelfT, A), T),
	contest(ConfigHash, Contest, T),
	config_ok(ConfigHash, T),
	not posted(pk_share(ConfigHash, Contest, _, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_combine_shares(ConfigHash, Contest, Hashes), A, T) :-
    posted(config(ConfigHash, _, _, 0, A), T),
	config_ok(ConfigHash, T),
	pk_shares_ok(ConfigHash, Contest, Hashes, T),
    not posted(pk_signature(ConfigHash, Contest, _, 0), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_sign_pk(ConfigHash, Contest, PkHash, Hashes), A, T) :-
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	pk_shares_ok(ConfigHash, Contest, Hashes, T),
	posted(pk_signature(ConfigHash, Contest, PkHash, 0), T),
    not posted(pk_signature(ConfigHash, Contest, PkHash, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_mix(ConfigHash, Contest, BallotsHash, PkHash), A, T) :-
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted(config(ConfigHash, _, _, 0, A), T),
	config_ok(ConfigHash, T),
	posted(ballots(ConfigHash, Contest, BallotsHash), T),
	not posted(mix_signature(ConfigHash, Contest, _, _, 0, 0), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_mix(ConfigHash, Contest, MixBallotsHash, PkHash), A, T) :-
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	SelfT > 0,
	% the previous mix was signed by its producer
	posted(mix_signature(ConfigHash, Contest, MixBallotsHash, _, SelfT - 1, SelfT - 1), T),
	% we have verified the previous mix
	posted(mix_signature(ConfigHash, Contest, MixBallotsHash, _, SelfT - 1, SelfT), T),
	not posted(mix_signature(ConfigHash, Contest, _, _, SelfT, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

% check mix 0
do(act_check_mix(ConfigHash, Contest, 0, MixHash, BallotsHash, PkHash), A, T) :-
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	% the mix to verify
	posted(mix_signature(ConfigHash, Contest, MixHash, BallotsHash, 0, 0), T),
	% input ballots to mix came from the ballotbox
	posted(ballots(ConfigHash, Contest, BallotsHash), T),
	not posted(mix_signature(ConfigHash, Contest, MixHash, BallotsHash, 0, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

% check mix n
do(act_check_mix(ConfigHash, Contest, MixerT, MixHash, MixBallotsHash, PkHash), A, T) :-
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	% the mix to verify
	posted(mix_signature(ConfigHash, Contest, MixHash, MixBallotsHash, MixerT, SignerT), T),
	MixerT > 0,
	% input ballots to mix came from a previous mix, thus (mixer_t - 1)
	posted(mix_signature(ConfigHash, Contest, MixBallotsHash, _, MixerT - 1, SignerT), T),
	not posted(mix_signature(ConfigHash, Contest, MixHash, MixBallotsHash, MixerT, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_partial_decrypt(ConfigHash, Contest, MixHash, Share), A, T) :-
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	posted(pk_share(ConfigHash, Contest, Share, SelfT), T),
	contest_mixed_ok(ConfigHash, Contest, MixHash, T),
	not posted(decryption(ConfigHash, Contest, _, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(act_combine_decryptions(ConfigHash, Contest, Decryptions, MixHash, Shares), A, T) :-
	decryptions_ok(ConfigHash, Contest, Decryptions, T),
	posted(config(ConfigHash, _, _, 0, A), T),
	config_ok(ConfigHash, T),
	contest_mixed_ok(ConfigHash, Contest, MixHash, T),
	pk_shares_ok(ConfigHash, Contest, Shares, T),
	not posted(plaintexts_signature(ConfigHash, Contest, _, 0), T),
	not pending(_, A, T),
	active(A, T), a(A).

do(check_plaintexts(ConfigHash, Contest, PlaintextsHash, Decryptions, MixHash, Shares), A, T) :-
	decryptions_ok(ConfigHash, Contest, Decryptions, T),
	posted(config(ConfigHash, _, _, SelfT, A), T),
	config_ok(ConfigHash, T),
	contest_mixed_ok(ConfigHash, Contest, MixHash, T),
	pk_shares_ok(ConfigHash, Contest, Shares, T),
	posted(plaintexts_signature(ConfigHash, Contest, PlaintextsHash, 0), T),
	not posted(plaintexts_signature(ConfigHash, Contest, PlaintextsHash, SelfT), T),
	not pending(_, A, T),
	active(A, T), a(A).


%**************** Input predicates ****************%

%********** config **********%

config_ok(ConfigHash, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_signed_upto(ConfigHash, TotalT - 1, T).

config_signed_upto(ConfigHash, 0, T) :-
	posted(config_signature(ConfigHash, 0), T).

config_signed_upto(ConfigHash, Trustee + 1, T) :-
    config_signed_upto(ConfigHash, Trustee, T),
    posted(config_signature(ConfigHash, Trustee + 1), T).

%********** shares **********%

pk_shares_ok(ConfigHash, Contest, Shares, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	pk_shares_upto(ConfigHash, Contest, TotalT - 1, Shares, T).

pk_shares_upto(ConfigHash, Contest, 0, Share, T) :-
	posted(pk_share(ConfigHash, Contest, Share, 0), T).

pk_shares_upto(ConfigHash, Contest, Trustee + 1, @concat(Shares, Share), T) :-
    pk_shares_upto(ConfigHash, Contest, Trustee, Shares, T),
    posted(pk_share(ConfigHash, Contest, Share, Trustee + 1), T).


%********** PK signatures **********%

pk_ok(ConfigHash, Contest, PkHash, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	pk_signed_upto(ConfigHash, Contest, PkHash, TotalT - 1, T).

pk_signed_upto(ConfigHash, Contest, PkHash, 0, T) :-
	posted(pk_signature(ConfigHash, Contest, PkHash, 0), T).

pk_signed_upto(ConfigHash, Contest, PkHash, Trustee + 1, T) :-
    pk_signed_upto(ConfigHash, Contest, PkHash, Trustee, T),
    posted(pk_signature(ConfigHash, Contest, PkHash, Trustee + 1), T).

%********** mixes **********%

mix_ok(ConfigHash, Contest, MixHash, BallotsHash, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	mix_signed_upto(ConfigHash, Contest, MixHash, BallotsHash, TotalT - 1, T).

mix_signed_upto(ConfigHash, Contest, MixHash, BallotsHash, 0, T) :-
	posted(mix_signature(ConfigHash, Contest, MixHash, BallotsHash, _, 0), T).

mix_signed_upto(ConfigHash, Contest, MixHash, BallotsHash, SignerT + 1, T) :-
	mix_signed_upto(ConfigHash, Contest, MixHash, BallotsHash, SignerT, T),
	posted(mix_signature(ConfigHash, Contest, MixHash, BallotsHash, _, SignerT + 1), T).

contest_mixed_ok(ConfigHash, Contest, MixHash, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	contest_mixed_upto(ConfigHash, Contest, MixHash, TotalT - 1, T).

contest_mixed_upto(ConfigHash, Contest, MixHash, 0, T) :-
	mix_ok(ConfigHash, Contest, MixHash, BallotsHash, T),
	posted(ballots(ConfigHash, Contest, BallotsHash), T).

contest_mixed_upto(ConfigHash, Contest, MixHash, Trustee + 1, T) :-
	contest_mixed_upto(ConfigHash, Contest, PreviousMixHash, Trustee, T),
	mix_ok(ConfigHash, Contest, MixHash, PreviousMixHash, T).

%********** partial decryptions **********%

decryptions_ok(ConfigHash, Contest, Decryptions, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	decryptions_upto(ConfigHash, Contest, TotalT - 1, Decryptions, T).

decryptions_upto(ConfigHash, Contest, 0, Decryption, T) :-
	posted(decryption(ConfigHash, Contest, Decryption, 0), T).

decryptions_upto(ConfigHash, Contest, Trustee + 1, @concat(Decryptions, Decryption), T) :-
    decryptions_upto(ConfigHash, Contest, Trustee, Decryptions, T),
    posted(decryption(ConfigHash, Contest, Decryption, Trustee + 1), T).

%********** plaintexts **********%

plaintexts_ok(ConfigHash, Contest, PlaintextsHash, T) :-
	posted(config(ConfigHash, _, TotalT, _, _), T),
	config_ok(ConfigHash, T),
	plaintexts_signed_upto(ConfigHash, Contest, PlaintextsHash, TotalT - 1, T).

plaintexts_signed_upto(ConfigHash, Contest, PlaintextsHash, 0, T) :-
	posted(plaintexts_signature(ConfigHash, Contest, PlaintextsHash, 0), T).

plaintexts_signed_upto(ConfigHash, Contest, PlaintextsHash, Trustee + 1, T) :-
    plaintexts_signed_upto(ConfigHash, Contest, PlaintextsHash, Trustee, T),
    posted(plaintexts_signature(ConfigHash, Contest, PlaintextsHash, Trustee + 1), T).

%********** contests **********%

contest(ConfigHash, Contests - 1, T) :-
	posted(config(ConfigHash, Contests, _, SelfT, _), T),
	t(T).
		
contest(ConfigHash, N - 1, T) :- contest(ConfigHash, N, T),
    N > 0.


%*******************************************************************************%
%******************************** SIMULATION ***********************************%
%*******************************************************************************%

#script (python)
from clingo import String

def concat(a, b):
	return String(a.string + "," + b.string)

def concat2(a, b):
	return String(a.string + "-" + str(b.number))
#end.

#const config_hash = "config_hash".
#const contests = 3.
#const auths = 2.
#const horizon = 18.

% in execution mode, A and T will be zero: a(0), t(0)
t(0..horizon).
a(0..auths - 1).

% The active predicate represents whether or not a given authority is active 
% for the duration of interval T.
%
% In execution mode, it is sufficient to set active(0, 0).
%
active(0..auths - 1, 0..horizon).
% represents a missing authority
% active(0..auths - 2, 0..horizon).

% Bootstrap protocol by adding config
%
% We're duplicating the A value so that each authority can select their particular
% configuration using that as an index, it just happens that the index
% is currently the only authority-specific information in the configuration
% In execution mode, A will be set to 0, so input fact parsing should
% generate an extra 0 in the config predicate
posted_at(config(config_hash, contests, auths, A, A), -1, 0) :- a(A).

% Once the pk is posted, simulate posting ballots by the ballotbox at T + 1,
% we need the second predicate to only generate posted_at once, at T + 1
posted_at(ballots(ConfigHash, Contest, "ballots_hash"), -1, T + 1) :- 
	pk_ok(ConfigHash, Contest, PkHash, T),
	posted_at(pk_signature(_, _, _, _), _, T).

%********** Work **********%

% In simulation, do predicates (actions) lead to pending predicates
% Pending work is work required by authority A when BB is at time T,
% according to conditions expressed in execution.
% Pending work does not lead to post instantaneously, since
%
% 1) A has to update to T (updating is modeled "inside" the pending state)
% 2) A has to compute the work
% 3) A has to successfully send work to BB
%
% NOTE: "Block pushing" of commits may not correspond to the current implementation
% if commits are pushed individually.
%
pending(config_signature(ConfigHash, A), A, T + 1) :- do(act_sign_config(ConfigHash), A, T).
pending(pk_share(ConfigHash, Contest, @concat2("share_hash_by", A), A), A, T + 1) :- do(act_post_share(ConfigHash, Contest), A, T).
pending(pk_signature(ConfigHash, Contest, @concat("combined", Hashes), A), A, T + 1) :- do(act_combine_shares(ConfigHash, Contest, Hashes), A, T).
pending(pk_signature(ConfigHash, Contest, PkHash, A), A, T + 1) :- do(act_sign_pk(ConfigHash, Contest, PkHash, Hashes), A, T).
pending(mix_signature(ConfigHash, Contest, @concat2("mix_hash_by", A), MixHash, A, A), A, T + 1) :- do(act_mix(ConfigHash, Contest, MixHash, PkHash), A, T).
pending(mix_signature(ConfigHash, Contest, MixHash, MixBallotsHash, MixerT, A), A, T + 1) :- do(act_check_mix(ConfigHash, Contest, MixerT, MixHash, MixBallotsHash, PkHash), A, T).
pending(decryption(ConfigHash, Contest, @concat2("decryption_hash_by", A), A), A, T + 1) :- do(act_partial_decrypt(ConfigHash, Contest, MixHash, Share), A, T).
pending(plaintexts_signature(ConfigHash, Contest, @concat("combined", Decryptions), A), A, T + 1) :- do(act_combine_decryptions(ConfigHash, Contest, Decryptions, MixHash, Shares), A, T).
pending(plaintexts_signature(ConfigHash, Contest, PlaintextsHash, A), A, T + 1) :- do(check_plaintexts(ConfigHash, Contest, PlaintextsHash, Decryptions, MixHash, Shares), A, T).

% pending work that has not been posted is still pending
pending(W, A, T + 1) :- not posted_at(W, A, T), pending(W, A, T), active(A, T + 1), t(T).

%********** Advance time step **********%

% Posting occurs non-deterministically, modeling 3 operations
%
% 1) Synchronizing from BB
% 2) Work completion
% 3) Sending to BB
%
%  Additionally, only 1 post can occur on the BB hashchain at a certain point,
%  meaning posts will have to be retried (by the losers) if there is a conflict.
% 
% A choice is used to model this set of concurrent events
% such that a serial sequence of posts results
%
1 { select(0..auths - 1, T) } 1 :- pending(W, A, T), t(T).
% only select an authority that has pending work
:- select(A, T), not pending(_, A, T).

% work posting: chosen pending predicate is converted into a posted_at predicate
posted_at(W, A, T) :- pending(W, A, T), select(A, T).

% Integrity constraint: ensure that there is a successful post for each T at which 
% there is at least one post attempt. The last predicate is included to prevent 
% unsatisfiability in case the horizon does not reach the posted_at time
% UPDATE superseded by ":- select(A, T), not pending(_, A, T)" above
% :- not posted_at(_, _, T), pending(_, _, T), t(T).

% Work W was posted by time T if it was posted at T or earlier
% When running in execution mode, input facts must generate posted() predicates 
% with time 0 and auth 0: posted(W, 0, 0)
posted(W, T) :- posted_at(W, A, Past), Past <= T, t(T).


%************* Model checking *************%
% completion
ok(T) :- plaintexts_ok(config_hash, 0..contests, _, T).

% allows setting via command line, eg
% clingo protocol.lp -c check=completion -c auths=2 -c contests=10 -c horizon=17 -e cautious --parallel-mode 8 -q
#const check = none.
model_check(check).

% COMPLETION
% Remove solutions that complete at some point
% If the problem is unsatisfiable it means completion is guaranteed at t=horizon
:- ok(0..horizon), model_check(completion).

% NON-COMPLETION
% Remove solutions that have not completed by the horizon
% If the problem is unsatisfiable it means completion is impossible
:- not ok(horizon), model_check(non_completion).

% #show.
#show ok/1.
% #show posted_at/3.
% #show pending/3.
% #show do/3.