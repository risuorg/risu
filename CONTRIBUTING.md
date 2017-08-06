### How to file a bug report
Please if you have any idea on any improvements please do not hesitate to open an [issue](https://github.com/zerodayz/citellus/issues/new).

### Future plans

The goal is to have a tool which collects all the rules across OpenStack operations.

When someone runs into an issue and fixes it, submits a patch so the next
time a team runs into the same issue can quickly check if there's already known.

We're not targetting just OpenStack, the framework allows to write tests for whatever can be checked with a shell script:
- System management
- Kernel settings
- Performance tunning
- etc

Please, do contribute your plugins for checking against new issues:

~~~
git clone git@github.com:zerodayz/citellus.git
git-review -s # to do setup
git checkout -b "your-new-branch"
# edit your files
git add $modified/files
git commit -m "Messsage for the changes done"
git-review # to submit review to gerrithub.io
~~~

From here, Tag on gerrithub provided URL some of the authors for review or wait for it to be reviewed and commented.

Check actual reviews at: <https://review.gerrithub.io/#/q/project:zerodayz/citellus>


Reddit post: <https://redd.it/6gv0uf>
Openstack-operators ML: <http://lists.openstack.org/pipermail/openstack-operators/2017-June/013789.html>

### How to write tests

Please refer to [templates](https://github.com/zerodayz/citellus/tree/master/doc/templates) folder including examples.
