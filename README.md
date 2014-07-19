shortstoryindex
===============

Short Story Index

The very beginning of a process/project to take some dumps of marc records from diverse sources and extract out the various short stories and upload them to a Neo4j graph database (see http://www.neo4j.com) and do some analysis. 

Files
===============
Main files
* filter_records.pl
* marc2neo4j.pl

Other files
* MARCUtils.pm
* create_pull_list.pl
* graphstyle.grass
* interesting_queries.txt

Right now this isn't a perl module/bundle, so there's not the usual perl makefile, make, make install. Sorry.

filter_records.pl
===============

./filter_record.pl part01.dat part02.dat ...

This takes in filenames of marc records and will parse through and pull out records that look like short stories, asking for y/n confirmation on ones it's not sure about.

Right now I'm using this against the Internet Archives Scriblio colleciton, see https://archive.org/details/marc_records_scriblio_net. There's some logic for keeping track of where I am.

I'm more concerned with higher precision than necessarily great recall, I mostly want to gather a pretty good corpus of material for pushing into neo4j.


marc2neo4j.pl
===============

./marc2neo4j.pl marc_collection.marc

Requires Neo4j to be installed and running.

Notice that the graph here is pretty rudimentray and basic. There's no authority control and we're going by exact match of title string contained in the title notes and the author names. (The author names are sometimes derived from the 100 note, using the perl MARC::Record author() method.

MARCUtils.pm
===============

Modules with some useful functions not provided by the MARC packages (that I've noticed).

create_pull_list.pl
===============
First batch of records were in marc-8, decided to change to unicode. This script is a nice little utility script that will get the bib_ids from an already processed batch, so I could "rerun" filter_records.pl to pull out the same records w/ no manual intervention.


interesting_queries.txt
===============

Some interesting queries (at least to me) in cypher, the NEo4j query language.


graphstyle.grass
===============

A stylesheet for displaying the titles of works and name of authors.




Current Progress
===============

This is a very rough first version. This seems to be pulling in from the collection fine and I've done some interesting queries against some of the data. I'm sure there's a lot of bugs, but I haven't had time to do much. Figure posting here might give me more motivation to keep tinkering with it ;).


To Dos
===============

Make the filter_records.pl a bit more like a rule engine, instead of haivng one large block of text.

Consider porting/moving to Java for the long haul.

More properties for the nodes.

More heuristics such as:
  - number of entries in ToC note
  - exclude works that mention terms like omnibus, novella, 

Better handling of "extended" 505 notes

Better handling of author information, or reconsider how to handle that.

Keep a lookup of bib ids or other identifiers so records don't need to be in a sorted order.