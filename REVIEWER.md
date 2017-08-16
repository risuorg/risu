# How to review a code change

We encourage you to contribute new plugins.  We use [gerrithub][] for
reviewing proposed changes.  The submission process looking something
like this:

[gerrithub]: https://gerrithub.io/

1. Clone the citellus repository:

        git clone git@github.com:zerodayz/citellus.git

2. Configure the `git review` tool:

        git review -s

3. Check out the proposed change branch:

         git-review -d 374436

4. Run UT against it

        tox

5. If everything passes successfully, perform a sample usage on available sosreport

        ~/citellus/citellus/citellus.py sosreportfolder
        
6. Provide comments and feedback on the gerrithub page for the proposed change

        git review
