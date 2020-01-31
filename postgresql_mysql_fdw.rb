require 'formula'

class PostgresqlMysqlFdw < Formula
  version '1.0'
  homepage 'https://github.com/EnterpriseDB/mysql_fdw'
  url 'https://github.com/EnterpriseDB/mysql_fdw/archive/REL-2_5_3.zip'
  sha256 '96b442972d60e0d57ecd8ca45644257719a51bd3eee20c696669d6a0856cb6b2'

  depends_on 'mysql@5.7'
  depends_on 'postgresql'
  depends_on 'cmake' => :build

  def postgresql
    # Follow the PostgreSQL linked keg back to the active Postgres installation
    # as it is common for people to avoid upgrading Postgres.
    Formulary.factory('postgresql').linked_keg.realpath
  end

  def install
    ENV.append("USE_PGXS", "1")

    system "make"

    # mysql_fdw includes the PGXS makefiles and so will install __everything__
    # into the Postgres keg instead of the mysql_fdw keg. Unfortunately, some
    # things have to be inside the Postgres keg in order to be function. So, we
    # install everything to a staging directory and manually move the pieces
    # into the appropriate prefixes.
    mkdir 'stage'
    system 'make', 'install', "DESTDIR=#{buildpath}/stage"

    so = Dir['stage/**/*.so']
    extensions = Dir['stage/**/extension/*']

    lib.install Dir["stage/**/lib/*"]
    (share/"postgresql/extension").install Dir["stage/**/share/postgresql/extension/*"]
  end
end
