# How to review a code change

We encourage you to contribute new plugins.  We use [gerrithub](https://review.gerrithub.io) for
reviewing proposed changes.  The submission process looking something
like this:

1. Clone the citellus repository:

        git clone git@github.com:citellusorg//citellus.git

1. Configure the `git-review` tool:

        git-review -s

1. Check out the proposed change branch:

         git-review -d 374436

1. Run UT against it

        tox

1. If everything passes successfully, perform a sample usage on available sosreport

        ~/citellus/citellus/citellus.py sosreportfolder

1. Provide comments and feedback on the gerrithub page for the proposed change

## Things to review

Below are some examples of things we do usually review:

- Use of LANG=C before commands we later grep to avoid end user localization to affect the strings we try to grep
- Use of ${var} vs $var
- Not mangle CITELLUS_ variables (usually leftovers when testing without using the provided `env-for-debug.sh` variable)
- Trailing spaces on lines or empty lines
- Reuse as maximum code between Live and snapshot mode
    - Use TRAP to generate files we might see in Live and use vars for it, for example:
    ~~~sh
    if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
        FILE="${CITELLUS_ROOT}/sos_commands/networking/ip_address"
    elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
        FILE=$(mktemp)
        trap "rm ${FILE}" EXIT
        ip address  > ${FILE} 2>&1
    fi
    ~~~

    - In this way, we do refer to same file in our is_required or is_lineinfile syntax and we do reouse the maximum code for the script
