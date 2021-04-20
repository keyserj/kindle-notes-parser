require 'active_support/inflector'
require 'optparse'
require 'shellwords'

# format of notes within file looks like this:
# Highlight (yellow) - Page 12
# [highlighted text, all on one line]
# Note - Page 12 [notes are optional!]
# [noted text, all on one line]
#
# example highlight_count command:
# cat test/html_stripped.txt | awk '/\(yellow\)/{print}' | wc -l
#
# example full parse command:
# cat test/html_stripped.txt | awk 'BEGIN{print "highlight count: 2"}; /\(yellow\)/{getline; print "* " $0; getline; if ($0 ~ /Note -/) {getline; print "\t" $0}}' > test/yellow.txt
def parse_highlight_color(color, output_book_path, output_html_stripped_path)
  highlight_count = `cat #{output_html_stripped_path} | awk '/\\(#{color}\\)/{print}' | wc -l`.to_i

  print_count = "BEGIN{print \"highlight count: #{highlight_count}\"}"
  print_notes = 'getline; print "* " $0; getline; if ($0 ~ /Note -/) {getline; print "\t" $0}'
  cmd_parse_notes = "awk '#{print_count}; /\\(#{color}\\)/{#{print_notes}}'"
  output_color_path = File.join(output_book_path, "#{color}.txt")

  `cat #{output_html_stripped_path} | #{cmd_parse_notes} > #{output_color_path}`
end

# example command:
# html-to-text --wordwrap=0 < test/test.html > test/html_stripped.txt
def parse_kindle_note(file_path, output_path)
  file_name = File.basename(file_path, ".*")
  output_book_path = File.join(output_path, file_name)
  `mkdir -p #{output_book_path}`
  output_html_stripped_path = File.join(output_book_path, "html_stripped.txt")

  # wordwrap=0 so that parsing doesn't split lines for word wrapping
  `html-to-text --wordwrap=0 < #{file_path} > #{output_html_stripped_path}`

  ["blue", "orange", "pink", "yellow"].each do |color|
    parse_highlight_color(color, output_book_path, output_html_stripped_path)
  end
end

def parse_kindle_notes(options)
  file_paths = options[:file] ? [options[:file]] : Dir[File.join(options[:directory], "*")]

  file_paths.each do |file_path|
    parse_kindle_note(file_path.shellescape, options[:output].shellescape)
  end
end

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby kindle-notes-parser.rb [-f file path|-d directory path] -o [output directory path]"

  opts.on("-f", "--file=file", "Path to file that contains kindle-exported notes")
  opts.on("-d", "--directory=directory", "Path to directory of files that contain kindle-exported notes")
  opts.on("-oOUTPUT", "--output=OUTPUT", "Output path to directory where parsed notes by book will go")

  opts.separator(
"\nExample: ruby kindle-notes-parser.rb -f /raw_exported/harry_potter.html -o /parsed
  creates:
/parsed/harry_potter/blue.txt
/parsed/harry_potter/html_stripped.txt
/parsed/harry_potter/orange.txt
/parsed/harry_potter/pink.txt
/parsed/harry_potter/yellow.txt"
  )

  opts.separator("\nExport kindle notes by going into your notebook for a book and clicking share->export notebook")
end

options = {}
option_parser.parse!(into: options)
raise "must pass a file path or a directory path, and not both" if !(options[:file].present? ^ options[:directory].present?)

parse_kindle_notes(options)

