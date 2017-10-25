#!/bin/bash
python setup.py extract_messages -F babel.cfg -k _L
find citellus -name "*.sh" -exec bash --dump-po-strings "{}" \; >> citellus/locale/citellus.pot


