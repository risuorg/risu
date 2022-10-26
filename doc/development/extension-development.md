## Writing extensions

Risu extensions should conform to the following standards:

- Written in python and stored in the `extensions` folder.
- Implement some base functions keeping arguments and data returned as in others:
  - `init()`
    - Returns list of triggers (array with strings)
  - `listplugins(options)`
    - Yields plugin object generator based on `options.include`, `options.exclude`
  - `get_description(plugin)`
    - Returns string for description based on plugin object
  - `run(plugin)`
    - Returns `(returncode, out, err)` after running a plugin object
  - `help()`
    - Returns string with description of extension
- Define extension in `listplugins` as 'back-end' based on the name of the file, so `findplugins`, `runplugin`, etc can find it properly and execute.
