%%% @author Fernando Benavides <fbenavides@novamens.com>
%%% @copyright 2009 Novamens S.R.L.
%%% @doc RFB Server Client Supervisor
-module(erfb_client).

-behaviour(supervisor).

-export([start_link/3, init/1, prep_stop/1]).

-include("erfblog.hrl").
-include("erfb.hrl").

-spec start_link(ip(), integer(), integer()) -> {ok, pid()}.
start_link(Ip, Port, Backlog) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, {Ip, Port, Backlog}).

-spec prep_stop(term()) -> term().
prep_stop(State) ->
    ?INFO("Preparing to stop~n\tChildren: ~p~n", [supervisor:which_children(?MODULE)]),
    [Module:prep_stop(State) ||
       {_, _, supervisor, [Module]} <- supervisor:which_children(?MODULE),
       lists:member({prep_stop, 1}, Module:module_info(exports))].

-spec init({ip(), integer(), integer()}) -> {ok, {tuple(), [tuple()]}}.
init({Ip, Port, Backlog}) ->
    Listener    = {erfb_client_listener, 
                   {erfb_client_listener, start_link, [Ip, Port, Backlog]},
                   permanent, 5000, worker, [erfb_client_listener]},
    Dispatcher  = {erfb_client_event_dispatcher,
                   {erfb_client_event_dispatcher, start_link, []},
                   permanent, 5000, worker, [erfb_client_event_dispatcher]},
    Manager     = {erfb_client_manager,
                   {erfb_client_manager, start_link, []},
                   permanent, 5000, supervisor, [erfb_client_manager]},
    {ok, {{one_for_one, 1, 10}, [Listener, Dispatcher, Manager]}}.