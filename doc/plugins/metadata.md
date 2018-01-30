# Metadata extension and its plugins

This extension and its plugins do output data in the following approach:

- stdout gets variable name
- stderr gets variable value

The data is obtained by executing (citellus-style) plugins under the 'metadata' folder also categorized so they can be included/excluded as desired using standard citellus switches

This data is then reported separately from remaining citellus output via Magui, for example:

~~~
 ./magui.py -mf metadata ../sosreport-controller-*
    _    
  _( )_  Magui:
 (_(ø)_) 
  /(_)   Multiple Analisis Generic Unifier and Interpreter
 \|      
  |/     

[{'description': u'Plugin for reporting back citellus metadata from all sosreports',
  'id': '0cff7ccb03e2cf61b73327953b9ce799',
  'plugin': 'metadata-outputs',
  'results': {'err': [{'backend': 'metadata',
                       'category': 'system',
                       'description': 'Sets sosreport date metadata',
                       'id': '077b4d1e1cec64e44afe6e34beb45548',
                       'long_name': 'reports date for sosreport',
                       'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/metadata/system/sosreport-date.sh',
                       'sosreport': {'../sosreport-controller-0-20171212110438': {'err': u'Tue Dec 12 11:05:25 UTC 2017\n',
                                                                                  'out': u'sosreport-date\n',
                                                                                  'rc': 10},
                                     '../sosreport-controller-1': {'err': u'Tue Dec 12 11:05:25 UTC 2017\n',
                                                                   'out': u'sosreport-date\n',
                                                                   'rc': 10}},
                       'subcategory': 'system'},
                      {'backend': 'metadata',
                       'category': 'system',
                       'description': 'Sets hostname metadata',
                       'id': '03a21df92121284f00367e2ea120e8d6',
                       'long_name': 'prepares hostname metadata',
                       'plugin': '/home/iranzo/DEVEL/citellus/citellusclient/plugins/metadata/system/hostname.sh',
                       'sosreport': {'../sosreport-controller-0-20171212110438': {'err': u'controller-0\n',
                                                                                  'out': u'hostname\n',
                                                                                  'rc': 10},
                                     '../sosreport-controller-1': {'err': u'controller-0\n',
                                                                   'out': u'hostname\n',
                                                                   'rc': 10}},
                       'subcategory': 'system'}],
              'out': '',
              'rc': 10},
  'time': 8.106231689453125e-05}]
~~~

In this case, we selected the magui plugin for metadata (`metadata-outputs`) and executed against a folder containing the same sosreport data.

The goal here is that we could then use magui plugins that act on sosreports which are for the same host, or extract specific data from a sosreport (like a pacemaker cluster VIP) and report if some sosreport is missing to be collected for a cluster member, for example to report RabbitMQ partition status.