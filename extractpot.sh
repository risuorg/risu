#!/bin/bash
# Copyright (C) 2017   Pablo Iranzo Gómez (Pablo.Iranzo@redhat.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# This program extracts language strings from python and bash files and
# combines them into one POT file to be used by translation tools

python setup.py extract_messages -F babel.cfg -k _L && find citellusclient -name "*.sh" -exec bash --dump-po-strings "{}" \;  |msguniq > citellusclient/locale/citellus-plugins.pot && cat citellusclient/locale/citellus.pot citellusclient/locale/citellus-plugins.pot|msguniq > citellusclient/locale/citellus-new.pot && cat citellusclient/locale/citellus-new.pot > citellusclient/locale/citellus.pot && rm -f citellusclient/locale/citellus-new.pot citellusclient/locale/citellus-plugins.pot
