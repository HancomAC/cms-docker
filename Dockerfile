FROM ubuntu:20.04
EXPOSE 80

# Install packages
RUN apt-get update -y
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-add-repository ppa:ondrej/php
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/GMT+9 apt-get -y install tzdata
RUN apt-get install build-essential openjdk-8-jdk-headless fp-compiler postgresql postgresql-client python3.6  \
                    cppreference-doc-en-html cgroup-lite libcap-dev zip python3.6-dev  \
                    libpq-dev libcups2-dev libyaml-dev libffi-dev python3-pip nginx-full python2.7 php7.2-cli php7.2-fpm \
                    phppgadmin texlive-latex-base a2ps haskell-platform rustc mono-mcs sudo wget  \
                    postgresql-server-dev-all python-dev screen libevent-dev -y
RUN pip3 install psycopg2 psycopg2-binary cython tornado sqlalchemy==1.3 netifaces pycryptodome==3.4.3 psutil  \
                 requests gevent greenlet werkzeug patool bcrypt chardet babel pyxdg jinja2 pyyaml pycups pypdf2 future

RUN wget -c https://github.com/cms-dev/cms/releases/download/v1.4.rc1/v1.4.rc1.tar.gz
RUN tar -zxvf v1.4.rc1.tar.gz


# Ready for CMS
WORKDIR /cms
RUN python3 prerequisites.py --as-root install
RUN chmod 777 /usr/local/lib/python3.8/dist-packages
RUN chown -R cmsuser /cms
RUN chmod 777 /usr/local/bin
USER cmsuser
RUN python3 setup.py install
RUN python3 prerequisites.py build
USER root
RUN chmod 775 /usr/local/bin

COPY cms.conf /cms/config/cms.conf
COPY pwd /pwd
RUN service postgresql start;su postgres -c "createuser --username=postgres cmsuser;createdb --username=postgres --owner=cmsuser cmsdb;psql --username=postgres --dbname=cmsdb --command='ALTER SCHEMA public OWNER TO cmsuser';psql --username=postgres --dbname=cmsdb --command='GRANT SELECT ON pg_largeobject TO cmsuser'"
CMD service postgresql start;sh
