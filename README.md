# kindle-notes-parser
Takes notes file(s) exported from Kindle and parses them by color.

Get exported files from Kindle by going into your notes for a book and clicking export:
![export_button](https://user-images.githubusercontent.com/13872370/115174776-7e05aa00-a08f-11eb-865d-af8c8aca22d7.jpg)


I wanted this because each color of highlight means something different for me, and for certain colors, I like to view those notes across all books, rather than scoped to a specific book. This script _does_ parse specific to each book, but in a format that's easy to take all the highlights of a color and paste them into another document for cross-book viewing pleasures.

The format (* [highlight]; ** [note]) was particularly chosen because it's easy to paste into OneNote, at which point, the [One Markdown](http://www.onenotegem.com/a/documents/gem-for-OneNote/Review_Tab/2019/1126/1214.html) add-in can be used to format all of these into bullets.

# requirements
1. [ruby](https://www.ruby-lang.org/en/downloads/)
2. [html-to-text](https://www.npmjs.com/package/html-to-text)

# usage
```
Usage: ruby kindle-notes-parser.rb [-f file path|-d directory path] -o [output directory path]
    -f, --file=file                  Path to file that contains kindle-exported notes
    -d, --directory=directory        Path to directory of files that contain kindle-exported notes
    -o, --output=OUTPUT              Output path to directory where parsed notes by book will go

Example: ruby kindle-notes-parser.rb -f /raw_exported/harry_potter.html -o /parsed
  creates:
/parsed/harry_potter/blue.txt
/parsed/harry_potter/orange.txt
/parsed/harry_potter/pink.txt
/parsed/harry_potter/yellow.txt

Export kindle notes by going into your notebook for a book and clicking share->export notebook
```
