# kindle-notes-parser
Takes notes file(s) exported from Kindle and parses them by color.

Get exported files from Kindle by going into your notes for a book and clicking export:
![export_button](https://user-images.githubusercontent.com/13872370/115174776-7e05aa00-a08f-11eb-865d-af8c8aca22d7.jpg)


I wanted this because each color of highlight means something different for me, and for certain colors, I like to view those notes across all books, rather than scoped to a specific book. This script _does_ parse specific to each book, but in a format that's easy to take all the highlights of a color and paste them into another document for cross-book viewing pleasures.

The format (\t[highlight]\n\t\t[note]) was particularly chosen because it's easy to paste into OneNote, where tabs create collapsible blocks.

# requirements
Tested via Linux, but it should probably work for Mac and Windows as well.
1. [ruby](https://www.ruby-lang.org/en/downloads/)
2. [html-to-text](https://www.npmjs.com/package/html-to-text)

# usage
```
Usage: ruby kindle-notes-parser.rb [-f file path|-d directory path] -p [parsed path] -o [organized path]
    -f, --file=file                  Path to file that contains kindle-exported notes
    -d, --directory=directory        Path to directory of files that contain kindle-exported notes
    -p, --parsed=PARSED              Path to directory where parsed notes by book will go
    -o, --organized=organized        Path to put the organized outputs, organized based on my colors' semantics

Example: ruby kindle-notes-parser.rb -d ./test/Raw_Exported -p ./test/Parsed
  creates:
./test/Parsed/test - Notebook/blue.txt
./test/Parsed/test - Notebook/html_stripped.txt
./test/Parsed/test - Notebook/orange.txt
./test/Parsed/test - Notebook/pink.txt
./test/Parsed/test - Notebook/yellow.txt

and -o ./test/Organized
  will additionally create:
./test/Organized/by_book/test.txt
./test/Organized/wisdoms.txt
./test/Organized/words.txt

Export kindle notes by going into your notebook for a book and clicking share->export notebook
```
