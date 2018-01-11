## Writing plugins

Magui plugins should conform to the following standards:

- Written in python and stored in the `maguiclient/plugins` folder following whatever desired hierarchy (for example, try to match citellus plugins structure for easyness in filtering)
- Implement some base functions keeping arguments and data returned as in others:
    - init()
        - Returns list of triggers (array with strings) (contain citellus plugin ID data to act on)
    - run(data)
        - Returns information that is later shown by magui
    - help()
        - Returns string with description of plugin

- Plugins for Magui should refer to processing of citellus data for doing it's work
    - In order to do so, each citellus plugins has a unique UID calculated via md5sum via relative path and plugin name.
    - Results are then filtered to get the data for that plugin ID, for example:
        ~~~py
        # Plugin ID to act on:
        # "131c0e0d785fae9811f2754262f0da9e"
        # Note that this ID is returned via 'triggers' in the init function, so only the data that this plugin can process is provided.

        returncode = citellus.RC_OKAY

        message = ''
        for ourdata in data:
            # 'err' in this case should be always equal to the md5sum of the file so that we can report the problem
            err = []
            for sosreport in ourdata['sosreport']:
                err.append(ourdata['sosreport'][sosreport]['err'])

            if len(sorted(set(err))) != 1:
                message = _("Pipeline.yaml contents differ across sosreports, please do check that the contents are the same and shared across the environment to ensure proper behavior.")
                returncode = citellus.RC_FAILED

        out = ''
        err = message
        return returncode, out, err
        ~~~