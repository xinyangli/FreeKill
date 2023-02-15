#ifndef _PACKMAN_H
#define _PACKMAN_H

class PackMan : public QObject {
  Q_OBJECT
public:
  PackMan(QObject *parent = nullptr);
  ~PackMan();
/*
  void readConfig();
  void writeConfig();
  void loadConfString(const QString &conf);
*/
  Q_INVOKABLE void downloadNewPack(const QString &url, bool useThread = false);
  Q_INVOKABLE void enablePack(const QString &pack);
  Q_INVOKABLE void disablePack(const QString &pack);
  Q_INVOKABLE void updatePack(const QString &pack);
  Q_INVOKABLE void upgradePack(const QString &pack);
  Q_INVOKABLE void removePack(const QString &pack);
  Q_INVOKABLE QString listPackages();
private:
  sqlite3 *db;

  int clone(const QString &url);
  int pull(const QString &name);
  int checkout(const QString &name, const QString &hash);
  int checkout_branch(const QString &name, const QString &branch);
  int status(const QString &name); // return 1 if the workdir is modified
  QString head(const QString &name); // get commit hash of HEAD
};

extern PackMan *Pacman;

#endif