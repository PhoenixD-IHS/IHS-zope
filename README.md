# IHS-zope
Docker container based on the [official python image](https://hub.docker.com/_/python/) that contains the basic code of the [Institutshaushaltssystem](https://github.com/PhoenixD-IHS/IHS).

THe following steps are done during build:
- Install requirements for running a [Zope](https://zope.dev/) instance.
- A zope instance is created via buildout.
- External data is loaded into the image
- zope.conf is replaced
- All Zope volumes are mounted
- The Zope authentication system at root level is replaced by a [PluggableAuthService](https://github.com/zopefoundation/Products.PluggableAuthService)

On every restart of the container, the root password of the Zope system is replaced by the one provided as environmental variable `ZOPE_ROOT_PASSWORD`.  

The most recent image can be downloaded from [DockerHub](https://hub.docker.com/r/svenkleinert/pxd-ihs-zope) via:
```bash
docker pull svenkleinert/pxd-ihs-zope:latest
```
