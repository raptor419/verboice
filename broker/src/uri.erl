-module(uri).
-export([parse/1, format/1, parse_qs/1, format_qs/1, get/2]).
-include("uri.hrl").

parse(Uri) ->
  case http_uri:parse(Uri) of
    {ok, {Scheme, UserInfo, Host, Port, Path, Query}} ->
      QueryString = parse_qs(Query),
      #uri{scheme = Scheme, user_info = UserInfo, host = Host, port = Port, path = Path, query_string = QueryString};
    Error -> Error
  end.

format(Uri = #uri{}) ->
  Scheme = atom_to_binary(Uri#uri.scheme, utf8),
  UserInfo = case Uri#uri.user_info of
    [] -> [];
    undefined -> [];
    _ -> [Uri#uri.user_info, $@]
  end,
  Port = case Uri#uri.port of
    undefined -> [];
    N ->
      DefaultPort = proplists:get_value(Uri#uri.scheme, http_uri:scheme_defaults()),
      case N of
        DefaultPort -> [];
        _ -> [$:, integer_to_list(N)]
      end
  end,
  Query = case Uri#uri.query_string of
    [] -> [];
    undefined -> [];
    QueryString -> [$?, format_qs_as_iolist(QueryString)]
  end,
  Path = case Uri#uri.path of
    undefined -> [];
    P -> P
  end,
  Bin = iolist_to_binary([Scheme, "://", UserInfo, Uri#uri.host, Port, Path, Query]),
  binary_to_list(Bin).

get(Options, Uri = #uri{}) ->
  Headers = case proplists:get_value(basic_auth, Options) of
    {User, Password} -> basic_auth(User, Password);
    _ -> []
  end,
  httpc:request(get, {Uri:format(), Headers}, [], []).

basic_auth(User, Password) ->
  [{"Authorization", "Basic " ++ base64:encode_to_string(iolist_to_binary([User, $:, Password]))}].

parse_qs([]) -> [];
parse_qs(QS) ->
  parse_qs(QS, QS).

parse_qs([], OrigQS) ->
  httpd:parse_query(OrigQS);
parse_qs([$? | Rest], _) ->
  httpd:parse_query(Rest);
parse_qs([_ | Rest], OrigQS) ->
  parse_qs(Rest, OrigQS).

format_qs(QS) ->
  binary_to_list(iolist_to_binary(format_qs_as_iolist(QS))).

format_qs_as_iolist(QS) -> format_qs_as_iolist(QS, []).
format_qs_as_iolist([], Out) -> Out;
format_qs_as_iolist([{K, V} | R], Out) ->
  Prev = case Out of
    [] -> [];
    _ -> [Out, $&]
  end,
  Key = http_uri:encode(util:to_string(K)),
  Value = http_uri:encode(util:to_string(V)),
  format_qs_as_iolist(R, [Prev, Key, $=, Value]).
