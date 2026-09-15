import re

with open('test/destructive_actions_test.dart', 'r') as f:
    content = f.read()

# Remove unused imports
content = re.sub(r"import 'package:flutter_google_datastore/main.dart';\n", "", content)
content = re.sub(r"import 'package:flutter_google_datastore/settings.dart';\n", "", content)
content = re.sub(r"import 'package:flutter_google_datastore/entity.dart';\n", "", content)
content = re.sub(r"import 'package:flutter_google_datastore/database.dart';\n", "", content)
content = re.sub(r"import 'package:flutter_google_datastore/datastoremain.dart';\n", "", content)

with open('test/destructive_actions_test.dart', 'w') as f:
    f.write(content)
