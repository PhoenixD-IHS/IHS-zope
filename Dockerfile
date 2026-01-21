FROM python:3.13.11-slim AS builder
ENV ZOPE_VERSION="5.13"

ENV WHEEL_VERSION="0.45.1"
ENV BUILDOUT_VERSION="5.1.1"

ENV MYSQLCLIENT_CFLAGS="-I/usr/include/mariadb/"
ENV MYSQLCLIENT_LDFLAGS="-L/usr/lib/x86_64-linux-gnu -lmariadb"
WORKDIR /usr/local/share/ihs

RUN apt-get update && apt-get install -y --no-install-recommends libmariadb-dev gcc

# install requirements
RUN \
pip install --no-cache-dir \
wheel==$WHEEL_VERSION \
zc.buildout==$BUILDOUT_VERSION

# create ihs folder 
RUN \
mkdir -p /usr/local/share/ihs && \
cat <<EOF > /usr/local/share/ihs/buildout.cfg
[buildout]
extends =
  https://zopefoundation.github.io/Zope/releases/$ZOPE_VERSION/versions-prod.cfg
parts =
	zopeinstance

[zopeinstance]
recipe = plone.recipe.zope2instance
user = root:thisisoverwrittenonstartup123!
http-address = 8080
zodb-temporary-storage = on
eggs =
    Products.PythonScripts
    Products.ExternalMethod
    Products.TemporaryFolder
    Products.Sessions
    Products.ZMySQLDA
    Products.PluggableAuthService
    reportlab
EOF

# build zope instance
RUN buildout

# copy external python script to container
RUN mkdir -p /usr/local/share/ihs/parts/zopeinstance/Extensions/
ADD zope_files/Extensions.tar.gz /usr/local/share/ihs/parts/zopeinstance/Extensions/

# copy index.html to container
COPY zope_files/index_html.zexp /usr/local/share/ihs/var/zopeinstance/import/

# create Select section of the zope instance
RUN mkdir -p /usr/local/share/ihs/ihs-select/
COPY zope_files/Select.zexp /usr/local/share/ihs/var/zopeinstance/import/

# replace zope config
COPY zope_files/zope.conf /usr/local/share/ihs/parts/zopeinstance/etc/

# setup acl_users, import Select and index.html
RUN mkdir -p /usr/local/share/ihs/ihs-instances/fs
RUN mkdir -p /usr/local/share/ihs/ihs-instances/blob
COPY zope_files/zope_setup.py /usr/local/share/ihs/

# copy script that updates the root password on startup to env variable
COPY zope_files/set_zope_password.py /usr/local/share/ihs/

FROM python:3.13.9-slim

COPY --from=builder /usr/local/share/ihs /usr/local/share/ihs
COPY --from=builder /usr/local/lib/python3.13/site-packages/ /usr/local/lib/python3.13/site-packages/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libmariadb.so /usr/lib/x86_64-linux-gnu/libmariadb.so
COPY --from=builder /usr/lib/x86_64-linux-gnu/libmariadb.so.3 /usr/lib/x86_64-linux-gnu/libmariadb.so.3

RUN \
/usr/local/share/ihs/bin/zopeinstance start && \
/usr/local/share/ihs/bin/zopeinstance stop


RUN /usr/local/share/ihs/bin/zopeinstance run /usr/local/share/ihs/zope_setup.py

RUN \
mv /usr/local/share/ihs/ihs-instances /usr/local/share/ihs/ihs-instances.templates && \
mkdir -p /usr/local/share/ihs/ihs-instances

# copy entrypoint and healthcheck
COPY zope_files/entrypoint.sh /
COPY zope_files/healthcheck.py /

EXPOSE 8080/tcp

CMD ["tail", "-f", "/dev/null"]
ENTRYPOINT ["bash", "/entrypoint.sh"]
