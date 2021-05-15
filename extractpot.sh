#!/bin/bash
# Copyright (C) 2017, 2018, 2021 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>

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

python setup.py extract_messages -F babel.cfg -k _L && find -L risuclient -name "*.sh" -exec bash --dump-po-strings "{}" \; | msguniq >risuclient/locale/risu-plugins.pot && cat risuclient/locale/risu.pot risuclient/locale/risu-plugins.pot | msguniq >risuclient/locale/risu-new.pot && cat risuclient/locale/risu-new.pot >risuclient/locale/risu.pot && rm -f risuclient/locale/risu-new.pot risuclient/locale/risu-plugins.pot
