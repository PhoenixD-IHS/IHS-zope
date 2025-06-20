FROM python:3.13.5
ENV ZOPE_VERSION="5.13"

WORKDIR /usr/local/share/ihs

# install requirements
RUN pip install --no-cache-dir wheel zc.buildout

# create ihs folder 
RUN mkdir -p /usr/local/share/ihs

# create build instructions
RUN echo '[buildout]\n\
extends =\n\
	https://zopefoundation.github.io/Zope/releases/'$ZOPE_VERSION'/versions-prod.cfg\n\
parts =\n\
	zopeinstance\n\
\n\
[zopeinstance]\n\
recipe = plone.recipe.zope2instance\n\
user = root:thisisoverwrittenonstartup123!\n\
http-address = 8080\n\
zodb-temporary-storage = on\n\
eggs =\n\
    Products.PythonScripts\n\
    Products.ExternalMethod\n\
    Products.TemporaryFolder\n\
    Products.Sessions\n\
    Products.ZMySQLDA\n\
    Products.PluggableAuthService\n\
    reportlab\n\
' > /usr/local/share/ihs/buildout.cfg

# back up instances if there are some
RUN if [ -d "/usr/local/share/ihs/ihs-instances/fs" ]; then cp -r /usr/local/share/ihs/ihs-instances/fs /usr/local/share/ihs/ihs-instances/fs.bak; fi
RUN if [ -d "/usr/local/share/ihs/ihs-instances/blob" ]; then cp -r /usr/local/share/ihs/ihs-instances/blob /usr/local/share/ihs/ihs-instances/blob.bak; fi

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

RUN /usr/local/share/ihs/bin/zopeinstance start
RUN /usr/local/share/ihs/bin/zopeinstance stop

RUN /usr/local/share/ihs/bin/zopeinstance run /usr/local/share/ihs/zope_setup.py

# copy script that updates the root password on startup to env variable
COPY zope_files/set_zope_password.py /usr/local/share/ihs/

# copy entrypoint
COPY zope_files/entrypoint.sh /

CMD ["tail", "-f", "/dev/null"]
ENTRYPOINT ["bash", "/entrypoint.sh"]
