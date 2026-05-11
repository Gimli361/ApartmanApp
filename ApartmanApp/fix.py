import os, re

for root, dirs, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if 'Theme.of(context).colorScheme.primary' in content:
                new_content = content.replace('Theme.of(context).colorScheme.primary', 'AppTheme.primaryColor')
                
                # ensure import is present
                import_stmt = "import 'package:apartman_app/core/theme.dart';"
                if 'AppTheme' in new_content and import_stmt not in new_content:
                    # add it after the last import
                    new_content = re.sub(r'(import\s+[^;]+;\n)+', lambda m: m.group(0) + import_stmt + '\n', new_content, count=1)

                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Fixed {filepath}')
