#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# Description: Autogroup logic for Magui - automatically groups sosreports
#              based on metadata similarities
# Copyright (C) 2018, 2019, 2021, 2026 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

from __future__ import print_function

try:
    import risuclient.shell as risu
except ImportError:
    import shell as risu


class AutoGroupManager(object):
    """
    Manages automatic grouping of sosreports based on metadata.

    Groups sosreports that share common characteristics (release, UUID, etc.)
    to enable comparative analysis across similar systems.
    """

    def __init__(self):
        """Initialize the AutoGroupManager"""
        self.groups = {}
        self.processed_groups = {}

    def generate_groups(self, metadata_results):
        """
        Generate autogroups from metadata plugin results.

        :param metadata_results: Results from metadata-outputs plugin
        :return: Dictionary of group names to list of sosreport paths

        Example output:
        {
            'release-7.5': ['host1', 'host2', 'host3'],
            'role-controller': ['host1', 'host4'],
        }
        """
        # Prefill dict with hosts
        hostsdict = {}
        for item in metadata_results:
            for elem in iter(item["sosreport"].keys()):
                if elem not in hostsdict:
                    hostsdict[elem] = {}

            name = item["name"]
            for host in item["sosreport"]:
                if item["sosreport"][host]["rc"] == risu.RC_OKAY:
                    value = item["sosreport"][host]["err"]
                else:
                    value = ""
                if value != "":
                    update = {name: value}
                    hostsdict[host].update(update)

        # At this point we have a dict of dicts:
        # hostsdict = {
        #     'host1': {'release': 'xxxx', 'UUID': 'YYYYY'},
        #     'host2': {'release': 'xxxx', 'UUID': 'ZZZZZ'},
        # }

        groups = {}

        # Create groups based on metadata values
        for element in hostsdict:
            for item in iter(hostsdict[element].items()):
                metadata_key = item[0]
                metadata_value = item[1]

                if metadata_key not in groups:
                    groups[metadata_key] = {}
                if metadata_value not in groups[metadata_key]:
                    groups[metadata_key][metadata_value] = [element]
                else:
                    groups[metadata_key][metadata_value].append(element)

        # Filter groups: only keep groups with >1 host but not all hosts
        results = {}
        for category in groups:
            for subcategory in groups[category]:
                group_name = "%s-%s" % (category, subcategory)
                host_list = groups[category][subcategory]

                # Only create group if it has multiple hosts but not all hosts
                if 1 < len(host_list) < len(hostsdict):
                    results[group_name] = host_list

        self.groups = results
        return results

    def find_next_target(self, available_groups):
        """
        Find optimal next target group to process.

        Sorts groups to find the next target that will reduce memory usage
        and maximize data reuse.

        :param available_groups: Dictionary of groups to choose from
        :return: Tuple of (target_group_name, updated_groups, sosreport_to_delete)

        The algorithm finds the group with the fewest unique sosreports,
        prioritizing groups that allow us to delete a sosreport from memory.
        """
        target = ""
        todel = False

        # Count how many groups each sosreport appears in
        subitemcount = {}

        for group_name in available_groups:
            for sosreport in available_groups[group_name]:
                if sosreport not in subitemcount:
                    subitemcount[sosreport] = {"count": 1, "where": [group_name]}
                else:
                    subitemcount[sosreport]["count"] += 1
                    subitemcount[sosreport]["where"].append(group_name)

        # Find the group with minimum unique sosreports
        minitems = len(subitemcount)

        for sosreport in subitemcount:
            count = subitemcount[sosreport]["count"]
            if count <= minitems:
                # This group has fewer unique sosreports
                target = subitemcount[sosreport]["where"][0]
                minitems = count

                # If this sosreport only appears in one group, we can delete it
                if minitems == 1:
                    todel = sosreport
                    break

        # Fallback if no target found
        if not target and subitemcount:
            # Pick any group
            first_sosreport = list(subitemcount.keys())[0]
            target = subitemcount[first_sosreport]["where"][0]
            todel = first_sosreport

        return target, available_groups, todel

    def is_duplicate_group(self, group_hosts):
        """
        Check if a group with these exact hosts was already processed.

        :param group_hosts: List of sosreport paths in the group
        :return: Tuple of (is_duplicate, existing_file_path or None)
        """
        sorted_hosts = sorted(set(group_hosts))

        for processed_file, processed_hosts in self.processed_groups.items():
            if sorted(set(processed_hosts)) == sorted_hosts:
                return True, processed_file

        return False, None

    def mark_processed(self, group_file, group_hosts):
        """
        Mark a group as processed to avoid duplicate work.

        :param group_file: File path where group results were saved
        :param group_hosts: List of sosreport paths in the group
        """
        self.processed_groups[group_file] = group_hosts

    def get_statistics(self):
        """
        Get statistics about generated groups.

        :return: Dictionary with group statistics
        """
        if not self.groups:
            return {"total_groups": 0, "total_hosts": 0, "avg_hosts_per_group": 0}

        total_hosts_in_groups = sum(len(hosts) for hosts in self.groups.values())

        return {
            "total_groups": len(self.groups),
            "total_hosts": len(set(h for hosts in self.groups.values() for h in hosts)),
            "avg_hosts_per_group": (
                total_hosts_in_groups / len(self.groups) if self.groups else 0
            ),
            "groups": {name: len(hosts) for name, hosts in self.groups.items()},
        }


def autogroups(autodata):
    """
    Legacy function for backward compatibility.

    Based on metadata-outputs plugin, generate possible groups for
    sosreport combination.

    :param autodata: metadata-outputs results
    :return: dict of groups and members
    """
    manager = AutoGroupManager()
    return manager.generate_groups(autodata)


def findtarget(data):
    """
    Legacy function for backward compatibility.

    Sorts autogroup to find next target to reduce memory usage and data reuse.

    :param data: autogroup dictionary
    :return: array made of target, data and elem to del (if any)
    """
    manager = AutoGroupManager()
    return manager.find_next_target(data)
