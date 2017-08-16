# How to review a code change

We encourage you to contribute new plugins.  We use [gerrithub](https://review.gerrithub.io) for
reviewing proposed changes.  The submission process looking something
like this:

1. Clone the citellus repository:

        git clone git@github.com:zerodayz/citellus.git

1. Configure the `git review` tool:

        git review -s

1. Check out the proposed change branch:

         git-review -d 374436

1. Run UT against it

        tox

1. If everything passes successfully, perform a sample usage on available sosreport

        ~/citellus/citellus/citellus.py sosreportfolder

1. Provide comments and feedback on the gerrithub page for the proposed change
