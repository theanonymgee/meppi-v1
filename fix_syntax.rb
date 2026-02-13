#!/usr/bin/env ruby

# Read the file
content = File.read('app/services/postgresql_importer.rb')

# Fix the syntax issues
# 1. Replace malformed begin/rescue blocks
content.gsub!(/^\s*begin\s*\n\s+\w+/, 'def method\n  begin')
content.gsub!(/^\s+results\[:\w+\] = import_\w+\s*\n\s+rescue/, '    results[:key] = import_method\n      rescue')

# 2. Fix missing commas in hashes
content.gsub!(/(\w+):\s*\d+\s+date:\s+Date\.today/, '\1:, \2, date: Date.today')

# 3. Fix missing end statements after methods
content.gsub!(/^\s+def \w+/, 'def method\n  ')

# Write back
File.write('app/services/postgresql_importer.rb', content)