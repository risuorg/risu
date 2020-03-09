## Generate a new release

For generating a new release on github and PyPI, tags must be used.

For example, to release version 1.1.0:

```sh
git checkout 1.1.0
git tag -am "Releasing 1.1.0" 1.1.0
```

Travis will detect this because of on: tags: true and will
initiate build of PyPI package and as well Github release
automatically.
