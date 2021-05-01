require 'active_support/inflector'
require 'optparse'
require 'shellwords'
require 'pry'

class Parser
  class << self
    # example command:
    # html-to-text --wordwrap=0 < test/Raw_Exported/test\ -\ Notebook.html > test/Parsed/test\ -\ Notebook/html_stripped.txt
    def parse_kindle_note(exported_file_path, parsed_path)
      exported_file_name = File.basename(exported_file_path, ".*")
      parsed_book_path = File.join(parsed_path, exported_file_name)
      `mkdir -p #{parsed_book_path}`
      parsed_html_stripped_path = File.join(parsed_book_path, "html_stripped.txt")

      # wordwrap=0 so that parsing doesn't split lines for word wrapping
      `html-to-text --wordwrap=0 < #{exported_file_path} > #{parsed_html_stripped_path}`

      ["yellow", "blue", "pink", "orange"].each do |color|
        parse_highlight_color(color, parsed_book_path, parsed_html_stripped_path)
      end
    end

    private

    # format of notes within file looks like this:
    # Highlight (yellow) - Page 12
    # [highlighted text, all on one line]
    # Note - Page 12 [notes are optional!]
    # [noted text, all on one line]
    #
    # example highlight_count command:
    # cat test/Parsed/test\ -\ Notebook/html_stripped.txt | awk '/\(yellow\)/{print}' | wc -l
    #
    # example full parse commands:
    # cat test/Parsed/test\ -\ Notebook/html_stripped.txt | awk 'BEGIN{print "yellow (2)"}; /\(yellow\)/{getline; print "\t" $0; getline; if ($0 ~ /Note -/) {getline; print "\t\t" $0}}' > test/Parsed/test\ -\ Notebook/yellow.txt
    # cat test/Parsed/test\ -\ Notebook/html_stripped.txt | awk 'BEGIN{print "blue (2)"}; /\(blue\)/{getline; print "\t" $0; getline; if ($0 ~ /Note -/) {getline; print "\t\t" $0}}' > test/Parsed/test\ -\ Notebook/blue.txt
    # cat test/Parsed/test\ -\ Notebook/html_stripped.txt | awk 'BEGIN{print "pink (2)"}; /\(pink\)/{getline; print "\t" $0; getline; if ($0 ~ /Note -/) {getline; print "\t\t" $0}}' > test/Parsed/test\ -\ Notebook/pink.txt
    # cat test/Parsed/test\ -\ Notebook/html_stripped.txt | awk 'BEGIN{print "orange (2)"}; /\(orange\)/{getline; print "\t" $0; getline; if ($0 ~ /Note -/) {getline; print "\t\t" $0}}' > test/Parsed/test\ -\ Notebook/orange.txt
    def parse_highlight_color(color, parsed_book_path, parsed_html_stripped_path)
      highlight_count = `cat #{parsed_html_stripped_path} | awk '/\\(#{color}\\)/{print}' | wc -l`.to_i
      return if highlight_count == 0

      print_count = "BEGIN{print \"#{color} (#{highlight_count})\"}"
      print_notes = 'getline; print "\t" $0; getline; if ($0 ~ /Note -/) {getline; print "\t\t" $0}'
      cmd_parse_notes = "awk '#{print_count}; /\\(#{color}\\)/{#{print_notes}}'"
      parsed_color_path = File.join(parsed_book_path, "#{color}.txt")

      `cat #{parsed_html_stripped_path} | #{cmd_parse_notes} > #{parsed_color_path}`
    end
  end
end

class Organizer
  class << self
    def organize(parsed_path, base_organized_path)
      initialize_organized_directories(base_organized_path)

      parsed_book_directories = Dir[File.join(parsed_path, "*")]

      parsed_book_directories.each do |parsed_book_directory|
        book = Book.new(parsed_directory: parsed_book_directory, base_organized_path: base_organized_path)
        organize_book(book, base_organized_path)
      end
    end

    private

    Color = Struct.new(:name, :category, :by_book?)

    def colors
      @colors ||= [
        Color.new("yellow", "reactions", true),
        Color.new("blue", "wows", true),
        Color.new("pink", "wisdoms", false),
        Color.new("orange", "words", false),
      ]
    end

    class Book
      attr_reader :parsed_directory, :title, :organized_file_path

      def initialize(parsed_directory:, base_organized_path:)
        @parsed_directory = parsed_directory
        @title = File.basename(parsed_directory).gsub("\\", "").gsub(" - Notebook", "")
        @organized_file_path = File.join(base_organized_path, BY_BOOK, "#{title}.txt").shellescape
      end
    end

    class BookColor
      attr_reader :parsed_file_path, :organized_file_path, :color_name, :header

      def initialize(color:, book:, base_organized_path:)
        @color_name = color.name
        @parsed_file_path = File.join(book.parsed_directory, "#{color.name}.txt").shellescape

        if color.by_book?
          @organized_file_path = book.organized_file_path
          @header = color.category.capitalize
        else
          @organized_file_path = File.join(base_organized_path, "#{color.category}.txt").shellescape
          @header = book.title
        end
      end
    end

    BY_BOOK = "by_book"

    def initialize_organized_directories(base_organized_path)
      `mkdir -p #{base_organized_path}/#{BY_BOOK}/`

      colors.select { |color| !color.by_book? }.each do |color|
        color_file_path = File.join(base_organized_path, "#{color.category}.txt")
        `rm -f #{color_file_path}`
      end
    end

    def organize_book(book, base_organized_path)
      `rm -f #{book.organized_file_path}`

      book_colors = colors
        .map { |color| BookColor.new(color: color, book: book, base_organized_path: base_organized_path) }
        .select { |book_color| File.file?(book_color.parsed_file_path.gsub("\\", "")) }

      book_colors.each do |book_color|
        organize_book_color(book_color)
      end
    end

    # example by book command:
    # cat ./test/Parsed/test\ -\ Notebook/yellow.txt | sed 's/yellow (/Reactions (/' >> ./test/Organized/by_book/test.txt
    #
    # example by color command:
    # cat ./test/Parsed/test\ -\ Notebook/pink.txt | sed 's/pink (/test (/' >> ./test/Organized/wisdoms.txt
    def organize_book_color(book_color)
      print_cmd = "cat #{book_color.parsed_file_path}"
      replace_cmd = "sed 's/#{book_color.color_name} (/#{book_color.header} (/'"

      `#{print_cmd} | #{replace_cmd} >> #{book_color.organized_file_path}`
    end
  end
end

def parse_kindle_notes(options)
  exported_file_paths = options[:file] ? [options[:file]] : Dir[File.join(options[:directory], "*")]
  escaped_parsed_path = options[:parsed].shellescape

  exported_file_paths.each do |exported_file_path|
    Parser.parse_kindle_note(exported_file_path.shellescape, escaped_parsed_path)
  end

  if options[:organized]
    Organizer.organize(escaped_parsed_path, options[:organized].shellescape)
  end
end

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby kindle-notes-parser.rb [-f file path|-d directory path] -p [parsed path] -o [organized path]"

  opts.on("-f", "--file=file", "Path to file that contains kindle-exported notes")
  opts.on("-d", "--directory=directory", "Path to directory of files that contain kindle-exported notes")
  opts.on("-pPARSED", "--parsed=PARSED", "Path to directory where parsed notes by book will go")
  opts.on("-o", "--organized=organized", "Path to put the organized outputs, organized based on my colors' semantics")

  opts.separator(
"\nExample: ruby kindle-notes-parser.rb -d ./test/Raw_Exported -p ./test/Parsed
  creates:
./test/Parsed/test - Notebook/blue.txt
./test/Parsed/test - Notebook/html_stripped.txt
./test/Parsed/test - Notebook/orange.txt
./test/Parsed/test - Notebook/pink.txt
./test/Parsed/test - Notebook/yellow.txt"
  )

  opts.separator(
"\nand -o ./test/Organized
  will additionally create:
./test/Organized/by_book/test.txt
./test/Organized/wisdoms.txt
./test/Organized/words.txt"
  )

  opts.separator("\nExport kindle notes by going into your notebook for a book and clicking share->export notebook")
end

options = {}
option_parser.parse!(into: options)
raise "must pass a file path or a directory path, and not both" if !(options[:file].present? ^ options[:directory].present?)

parse_kindle_notes(options)

