import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

search = r'''import 'package:flutter_google_datastore/kind.dart';'''
replace = r'''import 'package:flutter_google_datastore/kind.dart';
import 'package:flutter_google_datastore/datastoremain.dart';'''

content = re.sub(search, replace, content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
