require 'formula'

class PostgresqlMysqlFdw < Formula
  version '1.0'
  homepage 'https://github.com/EnterpriseDB/mysql_fdw'
  url 'https://github.com/EnterpriseDB/mysql_fdw/archive/REL-2_3_0.zip'
  sha256 '74970b5c5f11ccab19320b7317247e5066959589fb1ead0530da0eb1901e58b3'

  depends_on :mysql
  depends_on 'postgresql'
  depends_on 'cmake' => :build

  def postgresql
    # Follow the PostgreSQL linked keg back to the active Postgres installation
    # as it is common for people to avoid upgrading Postgres.
    Formula.factory('postgresql').linked_keg.realpath
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

    (postgresql/'lib').install so

    # Install extension scripts to the Postgres keg.
    # `CREATE EXTENSION mysql_fdw;` won't work if these are located elsewhere.
    (postgresql/'share/postgresql/extension').install extensions
  end
end
