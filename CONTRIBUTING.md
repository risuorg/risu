# How to file a bug report

If you have any suggestions for improvements please do not hesitate to
open an [issue](https://github.com/zerodayz/citellus/issues/new).

# How to contribute code

We encourage you to contribute new plugins.  We use [gerrithub][] for
reviewing proposed changes.  The submission process looking something
like this:

[gerrithub]: https://gerrithub.io/

1. Clone the citellus repository:

        git clone git@github.com:zerodayz/citellus.git

2. Configure the `git review` tool:

        git review -s

3. Check out a branch in which to make your changes:

        git checkout -b "your-new-branch"

4. Edit your files.

5. Update your local repository:

        git add $modified_files
        git commit -m "Messsage for the changes done"

6. Submit your changes for review:

        git review

Then wait for your changes to be reviewed.  It is common for reviewers
to request changes; when this happens:

1. Edit your files.

2. Update your existing commit. Do not create a new commit!

        git add $modified_files
        git commit --amend

3. Resubmit the change:

        git review

You can see pending and already merged actual changes at: <https://review.gerrithub.io/#/q/project:zerodayz/citellus>

### How to write tests

Please refer to the
[templates](https://github.com/zerodayz/citellus/tree/master/doc/templates)
folder for examples.
