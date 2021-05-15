## Ansible Playbook development

Risu does support execution of ansible playbooks as long as:

- `ansible-playbook` is installed and available in path

Playbooks can either:

- Include `RISU_ROOT` environment variable usage so they are executed in `snapshoot` mode.
- or not have it, so they will be executed only in `Live` mode.
- for playbooks that are valid for both Live and non Live, a comment with `RISU_HYBRID` should be in the lines, so Risu does flag it for both live and non live execution.

The idea behind this approach is that unmodified dropped-in the folder and risu will pick them up for Live execution.

If a script has to be customized, it will contain the RISU_ROOT variable, and they will be used for snapshoot mode.
