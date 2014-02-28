Contains code (and configuration files) for creating the documentation of the CVVisual project.

##Requirements to build the documentation

  - git
  - ruby
  - jekyll
  - doxygen
  - graphviz
  - Linux

##How write a piece of documentation

Create a file `[dasherised topic]-[category][:[order]].md`.

5 different categories are supported:

- `doc` - Documentation 
- `ref` - Reference
- `tut` - Tutorial
- `dev` - Developers
- `post` - Posts

Then just write your piece, but make sure to start the first line with a `#`, it's used to get the title of your writing.

Run the `build.rb` script from the `build` directory to create the HTML documentation and the API reference.
