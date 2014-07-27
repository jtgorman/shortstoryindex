# Some notes on various test cases

## Some of the test case files

* Basic Content Parsing - Test Case 1 - basic_contents_test1.mrc
** Source: UIU Catalog (z39.50)
** Modifed: no
** OCLC No: (OCoLC)ocm01858022
** Bib Id: 159599
** Downloaded: 2014-07-26
** Description: not extended, but follows title / author -- pattern (w/ trailing period)
* Basic Content Parsing - Test Case 2 - basic_contents_test2.mrc
** Source: UIU Catalog (z39.50)
** Modifed: yes - several issues w/ the Table of Contents, but best example of the format I could find. Yaz converted to marcxml, corrected, then back to mrc
** OCLC No: (OCoLC)ocm07272351
** Bib Id: 519763
** Downloaded: 2014-07-26
** Description: Follows a convetion of last name, initials, [person's title]. work title1. title2.-- 


## Editing files

When I needed to edit a test case, I typically did

` yaz-marcdump -i marc -o marcxml test_file.mrc > test_file.xml

Edited the XML

Then

` yaz-marcdump -i marc -o marcxml test_file.xml > test_file.mrc


## Sources

### UIU Catalog

Did some catalog searches against the "Classic catalog" trying to find differently formatted records by searching for records like short stories, horror, tales, and so on.

Then downloaded via z39.50 and using @1=12 w/ bib number taken from the staff marc view. (Url also works, but was already looking at the MARC to see

The z39.50 documentation on the CARLI website leads to a pretty flaky connection, but asking for some help pointed me towards the unproxied connection information.


` ~/shortstoryindex/t$  yaz-client -u UIU pz3950svr.carli.illinois.edu:14590/voyager -m {test_name.mrc}

Where {test_name.marc} is what you want the test case file name to be.

Then you'll search for the bib id and "show" it, which will also add it to the output file.

` Z> find @1=12 {bibid}

You should see a message saying one match was found

` Z> show 1 

and finally
 
` Z> q

To quit
==== Transcript of a download 


`~/shortstoryindex/t$ yaz-client -u UIU pz3950svr.carli.illinois.edu:14590/voyager -m basic_contents_test2.mrc
`Authentication set to Open (UIU)
`Connecting...OK.
`Sent initrequest.
`Connection accepted by v3 target.
`ID     : 34
`Name   : Voyager LMS - Z39.50 Server
`Version: 2007.2.5
`Options: search present
`Elapsed: 0.698160
` Z> find @1=12 159599
`Sent searchRequest.
`Received SearchResponse.
`Search was a success.
`Number of hits: 1
`records returned: 0
`Elapsed: 0.044431
`Z> show 1
`Sent presentRequest (1+1).
`Records: 1
`[VOYAGER]Record type: USmarc
`01318nam  2200217 i 4500
`001 159599
`005 20020415161347.0
`008 751015s1975    nyu           00001 eng  
`020    $a 0800876830 : $c $8.50
`035    $a (OCoLC)ocm01858022
`035    $9 AAR-0754
`040    $a DLC $c DLC $d UIU
`050 0  $a PZ1 $b .T43 $a PR1309.H6
`082    $a 823/.0872
`245 04 $a The Thrill of horror : $b 22 terrifying tales / $c edited by Hugh Lamb.
`260 0  $a New York : $b Taplinger Pub. Co., $c 1975.
`300    $a xiii, 207 p. ; $c 22 cm.
`505 0  $a Haggard, H. R. Only a dream.--Lewis, L. A. The meerschaum pipe.--Ellis, A. E. the life-buoy.--Jackson, T. G., Sir. The lady of Rosemount.--Gawsworth, J. How it happened.--Bryusov, V. In the mirror.--Burnett, J. "Calling Miss Marker."--Donovan, D. A night of horror.--Rolt, L. T. C. The shouting.--Birkin, C. The happy dancers.--Hodgson, W. H. The weed men. Cowles, F. Eyes for the blind.--Wakefield, H. R. Mr. Ash's studio.--Haining, R. Montage of death. Allen, G. Pallinghurst Barrow.--Scott, E. Randalls round.--Visiak, E. H. The skeleton at the feast. Medusan madness.--Benson, A. C. Out of the sea. Gilchrist, R. M. Witch in-grain.--Munby, A. N. L. The Tudor chimney.--James, M. R. The experiment.
`650  0 $a Horror tales, English
`650  0 $a Ghost stories, English.
`700 10 $a Lamb, Hugh.
`
`nextResultSetPosition = 2
`Elapsed: 0.056776
`See you later, alligator.



### Scriblio indexes

Obtained from using yaz-marcdump to split out the Scriblio 2007 files (https://archive.org/details/marc_records_scriblio_net). Usually used to pull out a record that caused issues while parsing.
