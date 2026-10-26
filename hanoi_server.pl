:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_cors)).
:- use_module(library(http/http_parameters)).

:- set_setting(http:cors, [*]).

:- http_handler(root(solve), solve_handler, []).
:- http_handler(root(validate), validate_handler, []).

% ---------- Solve the whole puzzle ----------

hanoi(0, _, _, _, []) :- !.
hanoi(N, From, To, Via, Moves) :-
    N > 0,
    N1 is N - 1,
    hanoi(N1, From, Via, To, Moves1),
    hanoi(N1, Via, To, From, Moves2),
    append(Moves1, [move(From,To)|Moves2], Moves).

solve_handler(Request) :-
    cors_enable,
    http_parameters(Request, [n(N, [integer, default(4)])]),
    N > 0, N =< 15,
    hanoi(N, a, c, b, Moves),
    maplist(move_to_json, Moves, JsonMoves),
    reply_json_dict(_{ moves: JsonMoves }, []),
    !.
solve_handler(_) :-
    cors_enable,
    reply_json_dict(_{ error: "invalid disk count" }, [status(400)]).


move_to_json(move(From, To), _{from: From, to: To}).

% ---------- Validate a single move (used by "Play it yourself") ----------
% ToSize = 0 means the destination peg is empty.

legal_move(_FromSize, 0) :- !.
legal_move(FromSize, ToSize) :- FromSize < ToSize.

validate_handler(Request) :-
    cors_enable,
    http_parameters(Request, [
        from_size(FromSize, [integer]),
        to_size(ToSize, [integer])
    ]),
    ( legal_move(FromSize, ToSize)
    -> reply_json_dict(_{ valid: true })
    ;  reply_json_dict(_{ valid: false })
    ),
    !.
validate_handler(_) :-
    cors_enable,
    reply_json_dict(_{ error: "invalid parameters" }, [status(400)]).
    
% ---------- Start the server ----------

:- initialization(
     ( http_server(http_dispatch, [port(8081)]),
       format("Hanoi server running at http://localhost:8081/solve~n")
     )
   ).
