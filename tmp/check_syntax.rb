# Fix syntax error in postgresql_importer.rb
content = File.read('app/services/postgresql_importer.rb')

# Remove extra 'end' statements
content.gsub!(/^\s+end\s*$/, '')

# Fix method definitions with incorrect begin/end placement
lines = content.lines
fixed_lines = []
indent_level = 0
skip_end = 0

lines.each do |line|
  if line.match(/^\s*def\s+\w+|^\s*begin\s*$/)
    skip_end = 0
    fixed_lines << line
  elsif line.match(/^\s*end\s*$/) && skip_end > 0
    skip_end -= 1
  else
    fixed_lines << line
  end
end

File.write('app/services/postgresql_importer.rb', fixed_lines.join)