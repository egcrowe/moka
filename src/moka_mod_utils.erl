%%% @doc Functions to manipulate loaded code

-module(moka_mod_utils).

-export([get_object_code/1, get_forms/1]).

-type forms() :: [erl_parse:abstract_form()].

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Returns the object code of a loadable module
%%
%% Independently of whether the module is loaded, this function fails if the
%% object module be loaded (i.e. if the beam file is not int the load path)
%%
%% @throws {cannot_get_object_code, Module}
-spec get_object_code(module()) -> binary().
get_object_code(Module) ->
    case code:get_object_code(Module) of
        {_Mod, Code, _File} -> Code;
        error -> throw({cannot_get_object_code, Module})
    end.

%% @doc Returns the abstract form of a loadable module
%%
%% This function throws `{no_abstract_code, Module}' when the module binary does
%% not contain an `abstract_code' chunk. This is usually because the module was
%% not compiled with `debug_info' or because it was stripped afterwards.
%%
%% It also throws `{cannot_get_object, Module}' if `Module' is not a loadable
%% erlang module (e.g. the name is misspelled, or the code is not compiled).
%%
%% @throws {no_abstract_code, module()
%%  | {cannot_get_object, module()}
-spec get_forms(module()) -> forms().
get_forms(Module) ->
    ObjectCode = get_object_code(Module),
    get_object_code_forms(ObjectCode).

%%%===================================================================
%%% Private Functions
%%%===================================================================
get_object_code_forms(Code) ->
    case beam_lib:chunks(Code, [abstract_code]) of
        {ok, {_Mod, Result}} -> get_abstract_code_forms(Result);
        {error, beam_lib, Reason} -> throw({cannot_get_abstract_code, Reason})
    end.

get_abstract_code_forms([{abstract_code, {Version, Forms}}]) ->
    check_abs_vsn(Version),
    Forms;
get_abstract_code_forms([{abstract_code, no_abstract_code}]) ->
    throw(no_abstract_code).

check_abs_vsn(raw_abstract_v1) -> ok;
check_abs_vsn(Other) -> throw({unsupported_abstract_code_version, Other}).
