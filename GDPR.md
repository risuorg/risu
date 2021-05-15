**Table of contents**

<!-- TOC depthFrom:1 insertAnchor:false orderedList:false -->

- [GDPR](#gdpr)

<!-- /TOC -->

# GDPR

GDPR <https://www.eugdpr.org/> is a Regulation created to safeguard private data access, rectification, removal, etc.

Risu or Magui processes the information already in your sosreports (which you can clean using tools like [SosCleaner](https://github.com/RedHatGov/soscleaner)) and stores in the same folder where the sosreport has been uncompressed.

If the sosreport contains data under the scope of GDPR, the generated files by Risu or Magui (`risu.json` or `magui-*.json`) might contain excerpts of that data (but unlikely as we do output information on the error found, not the actual line that triggered it).

Also remember, that, when running Risu or Magui:

- You're downloading Risu/Magui to your system and execute locally
- You're using a sealed container against the folder you define

Such as, the system where it's executed will contain forementioned files that should be removed.

In case of remote execution in Magui, a temporary folder with the contents of those files is available at `/tmp/risu.json` for each host that was added and a local (for the executing host) folder named `/tmp/risu/hostrun/` will contain the files transferred from remote systems to local one.

So, briefing:

- For LIVE executions
  - No data is stored
- For non-LIVE executions

  - `risu.json` in sosreport folder or the path you've defined with -o
  - `magui*.json` in the folder where you executed `magui`

- When using Magui's ansible host file for remote execution, additionally:
  - `/tmp/risu.json` on remote hosts
  - `/tmp/risu` folder on calling host
