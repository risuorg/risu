## Writing plugins

Magui plugins should conform to the following standards:

- Written in python and stored in the `magplug` folder following whatever desired hierarchy (for example, try to match citellus plugins structure for easyness in filtering)
- Implement some base functions keeping arguments and data returned as in others:
    - init()
        - Returns list of triggers (array with strings) (empty)
    - run(data)
        - Returns information that is later shown by magui
    - help()
        - Returns string with description of plugin

- Plugins for Magui should refer to processing of citellus data for doing it's work
    - In order to do so, each citellus plugins has a unique UID calculated via md5sum via relative path and plugin name.
    - Results are then filtered to get the data for that plugin ID, for example:
        ~~~py
        # Plugin ID to act on:
        plugid = "131c0e0d785fae9811f2754262f0da9e"

        ourdata = False
        for item in data:
            if data[item]['id'] == plugid:
                ourdata = data[item]

        message = []

        if ourdata:
            # 'err' in this case should be always equal to the md5sum of the file so that we can report the problem
            err = []
            for sosreport in ourdata['sosreport']:
                err.append(ourdata['sosreport'][sosreport]['err'])

            if len(sorted(set(err))) != 1:
                message = _("Pipeline.yaml contents differ across sosreports, please do check that the contents are the same and shared across the environment to ensure proper behavior.")
        return message
        ~~~