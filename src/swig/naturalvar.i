// ------------------------------------------------------
// type bindings
// ------------------------------------------------------

// LuaFunction(int) and lua function
%naturalvar LuaFunction;
%typemap(in) LuaFunction
%{
if (lua_isfunction(L, $input)) {
  lua_pushvalue(L, $input);
  $1 = luaL_ref(L, LUA_REGISTRYINDEX);
} else {
  $1 = 0;
}
%}

%typemap(out) LuaFunction
%{
lua_rawgeti(L, LUA_REGISTRYINDEX, $1);
SWIG_arg ++;
%}

// QString and lua string
%naturalvar QString;

%typemap(in, checkfn = "lua_isstring") QString
%{ $1 = lua_tostring(L, $input); %}

%typemap(out) QString
%{
  if ($1.isEmpty()) {
    lua_pushstring(L, "");
  } else if ($1 == "__notready") {
    lua_pushstring(L, "__notready");
  } else {
    lua_pushstring(L, $1.toUtf8());
  }
  SWIG_arg++;
%}

// const QString &
%typemap(arginit) QString const &
  "QString $1_str;"

%typemap(in, checkfn = "lua_isstring") QString const &
%{
  $1_str = QString::fromUtf8(lua_tostring(L, $input));
  $1 = &$1_str;
%}

%typemap(out) QString const &
%{
  if ($1.isEmpty()) {
    lua_pushstring(L, "");
  } else if ($1 == "__notready") {
    lua_pushstring(L, "__notready");
  } else {
    lua_pushstring(L, $1.toUtf8());
  }
  SWIG_arg++;
%}

// QStringList
%naturalvar QStringList;

%typemap(in, checkfn = "lua_istable") QStringList
%{
for (size_t i = 0; i < lua_rawlen(L, $input); ++i) {
  lua_rawgeti(L, $input, i + 1);
  const char *elem = luaL_checkstring(L, -1);
  $1 << QString::fromUtf8(QByteArray(elem));
  lua_pop(L, 1);
}
%}

%typemap(out) QStringList
%{
lua_createtable(L, $1.length(), 0);

for (int i = 0; i < $1.length(); i++) {
  QString str = $1.at(i);
  auto bytes = str.toUtf8();
  lua_pushstring(L, bytes.constData());
  lua_rawseti(L, -2, i + 1);
}

SWIG_arg++;
%}

%typemap(typecheck) QStringList
%{
  $1 = lua_istable(L, $input) ? 1 : 0;
%}


