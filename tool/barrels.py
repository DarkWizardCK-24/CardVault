"""Regenerates the barrel files (core.dart / widgets.dart / screens.dart)."""
import os

NEW = 'lib'


def barrel(rel_dirs, out):
    files = []
    for d in rel_dirs:
        for dp, _, fs in os.walk(os.path.join(NEW, d)):
            for f in sorted(fs):
                rel = os.path.relpath(os.path.join(dp, f), NEW).replace(os.sep, '/')
                if f.endswith('.dart') and rel != out and not f.endswith(('_io.dart', '_web.dart')):
                    files.append(rel)
    with open(os.path.join(NEW, out), 'w', encoding='utf-8') as fh:
        fh.write(''.join("export 'package:cardvault/%s';\n" % f for f in sorted(files)))


barrel(['ui/widgets'], 'ui/widgets/widgets.dart')
barrel(['ui/screens'], 'ui/screens/screens.dart')
barrel(['core/theme', 'core/models', 'core/data', 'core/security', 'core/services', 'core/utils'], 'core/core.dart')
print('barrels ok')
