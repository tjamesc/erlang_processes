%% - Thomas Carriero
%% - Minjae Kung

-module(server_chain).
-export([start/0, serv1_loop/1, serv2_loop/1, serv3_loop/1]).

start() ->
    Serv3 = spawn(?MODULE, serv3_loop, [0]),
    Serv2 = spawn(?MODULE, serv2_loop, [Serv3]),
    Serv1 = spawn(?MODULE, serv1_loop, [Serv2]),
    main_loop(Serv1).

main_loop(Serv1) ->
    case io:read("> ") of
        {ok, all_done} -> ok;
        {ok, Msg} ->
            Serv1 ! Msg,
            main_loop(Serv1);
        _ -> main_loop(Serv1)
    end.

serv1_loop(NextPid) ->
    receive
        halt ->
            NextPid ! halt,
            io:format("(serv1) Halting...~n"),
            ok;
        {add, A, B} when is_number(A), is_number(B) ->
            io:format("(serv1) add: ~p + ~p = ~p~n", [A, B, A+B]),
            serv1_loop(NextPid);
        {sub, A, B} when is_number(A), is_number(B) ->
            io:format("(serv1) sub: ~p - ~p = ~p~n", [A, B, A-B]),
            serv1_loop(NextPid);
        {mult, A, B} when is_number(A), is_number(B) ->
            io:format("(serv1) mult: ~p * ~p = ~p~n", [A, B, A*B]),
            serv1_loop(NextPid);
        {'div', A, B} when is_number(A), is_number(B), B /= 0 ->
            io:format("(serv1) div: ~p / ~p = ~p~n", [A, B, A/B]),
            serv1_loop(NextPid);
        {'div', _, 0} ->
            io:format("(serv1) Error: division by zero~n"),
            serv1_loop(NextPid);
        {neg, A} when is_number(A) ->
            io:format("(serv1) neg: ~p negated is ~p~n", [A, -A]),
            serv1_loop(NextPid);
        {sqrt, A} when is_number(A), A >= 0 ->
            io:format("(serv1) sqrt: sqrt(~p) = ~p~n", [A, math:sqrt(A)]),
            serv1_loop(NextPid);
        {sqrt, A} when is_number(A) ->
            io:format("(serv1) Error: sqrt of negative number ~p~n", [A]),
            serv1_loop(NextPid);
        Other ->
            NextPid ! Other,
            serv1_loop(NextPid)
    end.

serv2_loop(NextPid) ->
    receive
        halt ->
            NextPid ! halt,
            io:format("(serv2) Halting...~n"),
            ok;
        List when is_list(List) ->
            case List of
                [H | _] when is_number(H) ->
                    Numbers = lists:filter(fun(X) -> is_number(X) end, List),
                    if
                        is_integer(H) ->
                            Sum = lists:sum(Numbers),
                            io:format("(serv2) Sum: ~p~n", [Sum]);
                        is_float(H) ->
                            Product = lists:foldl(fun(X, Acc) -> X * Acc end, 1.0, Numbers),
                            io:format("(serv2) Product: ~p~n", [Product])
                    end,
                    serv2_loop(NextPid);
                _ ->
                    NextPid ! List,
                    serv2_loop(NextPid)
            end;
        Other ->
            NextPid ! Other,
            serv2_loop(NextPid)
    end.

serv3_loop(Count) ->
    receive
        halt ->
            io:format("(serv3) Halting. Unprocessed messages: ~p~n", [Count]),
            ok;
        {error, Msg} ->
            io:format("(serv3) Error: ~p~n", [Msg]),
            serv3_loop(Count);
        Other ->
            io:format("(serv3) Not handled: ~p. Total: ~p~n", [Other, Count+1]),
            serv3_loop(Count + 1)
    end.