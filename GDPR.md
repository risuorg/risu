# GDPR

GDPR <https://www.eugdpr.org/> is a Regulation created to safeguard private data access, rectification, removal, etc.

Citellus or Magui processes the information already in your sosreports (which you can clean using tools like [SosCleaner](https://github.com/RedHatGov/soscleaner)) and stores in the same folder where the sosreport has been uncompressed.

If the sosreport contains data under the scope of GDPR, the generated files by Citellus or Magui (`citellus.json` or `magui-*.json`) might contain excerpts of that data (but unlikely as we do output information on the error found, not the actual line that triggered it).

Also remember, that, when running Citellus or Magui:

- You're downloading Citellus/Magui to your system and execute locally
- You're using a sealed container against the folder you define

Such as, the system where it's executed will contain forementioned files that should be removed.

In case of remote execution in Magui, a temporary folder with the contents of those files is available at `/tmp/citellus.json` for each host that was added and a local (for the executing host) folder named `/tmp/citellus/hostrun/` will contain the files transferred from remote systems to local one.

So, briefing:

- For LIVE executions
    - No data is stored
- For non-LIVE executions
    - `citellus.json` in sosreport folder or the path you've defined with -o
    - `magui*.json` in the folder where you executed `magui`

- When using Magui's ansible host file for remote execution, additionally:
    - `/tmp/citellus.json` on remote hosts 
    - `/tmp/citellus` folder on calling host
