**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [How to review a code change](#how-to-review-a-code-change)
  - [Things to review](#things-to-review)

<!-- /TOC -->

# How to review a code change

Check out the PR submitted locally to validate (UT's, etc are already run from GH side)

1.  If everything passes successfully, perform a sample usage on available sosreport

        ~/citellus/citellus/citellus.py sosreportfolder

1.  Provide comments and feedback on the PR page for the proposed change

## Things to review

Below are some examples of things we do usually review:

- Use of LANG=C before commands we later grep to avoid end user localization to affect the strings we try to grep
- Use of ${var} vs $var
- Not mangle CITELLUS\_ variables (usually leftovers when testing without using the provided `env-for-debug.sh` variable)
- Trailing spaces on lines or empty lines
- Reuse as maximum code between Live and snapshot mode

  - Use TRAP to generate files we might see in Live and use vars for it, for example:

  ```sh
  if [[ ${CITELLUS_LIVE} -eq 0 ]]; then
      FILE="${CITELLUS_ROOT}/sos_commands/networking/ip_address"
  elif [[ ${CITELLUS_LIVE} -eq 1 ]];then
      FILE=$(mktemp)
      trap "rm ${FILE}" EXIT
      ip address  > ${FILE} 2>&1
  fi
  ```

  - In this way, we do refer to same file in our is_required or is_lineinfile syntax and we do reouse the maximum code for the script
