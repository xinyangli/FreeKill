#ifndef _GLOBAL_H
#define _GLOBAL_H

// utilities

lua_State *CreateLuaState();
bool DoLuaScript(lua_State *L, const char *script);

#ifndef Q_OS_WASM
sqlite3 *OpenDatabase(const QString &filename = "./server/users.db", const QString &initSql = "./server/init.sql");
QJsonArray SelectFromDatabase(sqlite3 *db, const QString &sql);
// For Lua
QString SelectFromDb(sqlite3 *db, const QString &sql);
void ExecSQL(sqlite3 *db, const QString &sql);
void CloseDatabase(sqlite3 *db);

RSA *InitServerRSA();
#endif

QString calcFileMD5();
QByteArray JsonArray2Bytes(const QJsonArray &arr);
QJsonDocument String2Json(const QString &str);

#endif // _GLOBAL_H
