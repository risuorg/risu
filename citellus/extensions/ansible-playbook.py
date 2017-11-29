#!/usr/bin/env python
# encoding: utf-8
#
# Description: Extension for processing ansible playbooks
# Author: Pablo Iranzo Gomez (Pablo.Iranzo@gmail.com)
from __future__ import print_function
from citellus import findplugins, citellusdir

PlaybooksFolder = "playbooks"

import json
from collections import namedtuple
from ansible.parsing.dataloader import DataLoader
from ansible.vars.manager import VariableManager
from ansible.inventory.manager import InventoryManager
from ansible.playbook.play import Play
from ansible.executor.task_queue_manager import TaskQueueManager
from ansible.plugins.callback import CallbackBase
import os


def init():
    """
    Initializes module
    :return: List of triggers for plugin
    """
    triggers = []
    return triggers

def runplaybook(playbook):
    class ResultCallback(CallbackBase):
        """A sample callback plugin used for performing an action as results come in

        If you want to collect all results into a single object for processing at
        the end of the execution, look into utilizing the ``json`` callback plugin
        or writing your own custom callback plugin
        """

        def v2_runner_on_ok(self, result, **kwargs):
            """Print a json representation of the result

            This method could store the result in an instance attribute for retrieval later
            """
            host = result._host
            print(json.dumps({host.name: result._result}, indent=4))

    Options = namedtuple('Options',
                         ['connection', 'module_path', 'forks', 'become', 'become_method', 'become_user', 'check',
                          'diff'])
    # initialize needed objects
    loader = DataLoader()
    options = Options(connection='local', module_path='/path/to/mymodules', forks=100, become=None, become_method=None,
                      become_user=None, check=False,
                      diff=False)
    passwords = dict(vault_pass='secret')

    # Instantiate our ResultCallback for handling results as they come in
    results_callback = ResultCallback()

    # create inventory and pass to var manager
    inventory = InventoryManager(loader=loader, sources=['localhost'])
    variable_manager = VariableManager(loader=loader, inventory=inventory)

    # create play with tasks
    play_source = dict(
        name="Ansible Play",
        hosts='localhost',
        gather_facts='no',
        tasks=[
            dict(action=dict(module='shell', args='ls'), register='shell_out'),
            dict(action=dict(module='debug', args=dict(msg='{{shell_out.stdout}}')))
        ]
    )
    play = Play().load(play_source, variable_manager=variable_manager, loader=loader)

    # actually run it
    tqm = None
    try:
        tqm = TaskQueueManager(
            inventory=inventory,
            variable_manager=variable_manager,
            loader=loader,
            options=options,
            passwords=passwords,
            stdout_callback=results_callback,  # Use our custom callback instead of the ``default`` callback plugin
        )
        result = tqm.run(play)
    finally:
        if tqm is not None:
            tqm.cleanup()



def run(options):  # do not edit this line
    """
    Executes plugin
    :param message: message to run against
    :return:
    """
    print("We run it!!, yeeess we run it!")

    playbooksdir=os.path.join(citellusdir,PlaybooksFolder)
    for playbook in findplugins(folders=[playbooksdir], include=options.include, exclude=options.exclude, executables=False):
        print("Running %s" % playbook)
        runplaybook(playbook)

    return


def help():  # do not edit this line
    """
    Returns help for plugin
    :return: help text
    """

    commandtext = "This plugin proceses Ansible playbooks against the system"
    return commandtext
