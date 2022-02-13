# BookFramer

MacOS application for editing novels with BBEdit

## History

BookFramer is a native Mac app that performs the same task as [PyBookBuilder](https://github.com/sbiickert/PyBookBuilder). I originally wrote PyBookBuilder because I'd been working with [npyscreen](https://npyscreen.readthedocs.io) quite a bit and having fun making terminal apps. But as PyBookBuilder became more complex, I was starting to find the incessant jumping in and out of screens cumbersome.

BookFramer took the core functionality from PyBookBuilder and became a document-based Cocoa (AppKit) MacOS App.

## What is it?

BookFramer is not a Markdown editor... yet. It is meant to work *with* a Markdown editor, providing the big-picture view of a novel. My weapon of choice is [BBEdit](https://barebones.com) and this application reflects that, although there's no reason that a different app could be used. BookFramer is a manager, and BBEdit is an editor. They both open and modify the same file.

The core of the process is the BFD (BookFramer Document) file. It is Markdown. What sets it apart from a standard Markdown file is that there are HTML comments with JSON inside. These "headers" appear at the start of the document and at the beginning of each section, supplying metadata about the book and each section, respectively. Other than that, the BFD uses standard Markdown syntax. Heading 1 is the title, Heading 2 denotes each chapter.

BookFramer works with these "blocks" of the novel, and can add, remove and modify the headers for:

- the Book
- Chapters
- SubChapters

![Manage View](https://github.com/sbiickert/BookFramer/blob/main/Screenshots/manage.png)

To see the actual content of a Chapter or SubChapter, switch to the Preview:

![Preview View](https://github.com/sbiickert/BookFramer/blob/main/Screenshots/preview.png)

The preview view has a basic grammar checker for reading difficulty (FRES), passive voice and adverbs. There is a fair bit to do to make it better, but the basics are there.

## What else?

- The Markdown editor is BBEdit. It calls out to the bbedit Unix executable via [NSUserUnixTask](https://developer.apple.com/documentation/foundation/nsuserunixtask). The path to the executable is set in the Preferences window.
- Exporting to PDF uses [pandoc](https://pandoc.org) and pdflatex. As with the bbedit executable, the paths to these are also set in the Preferences window.
- BookFramer can import plain Markdown. Use heading 1, heading 2 for the book title and chapter titles, and break subchapters with a horizontal line (doesn't matter which way you denote it in Markdown). The headers will be empty (of course) and you can start filling them in and save it as a BFD.

## The Future

I'd like to experiment with actually making BookFramer a Markdown editor, but that might wait for a while. For the moment, just interoperating with a kick-ass editor is good enough.
