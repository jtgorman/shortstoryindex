#!/usr/bin/env perl

use strict ;
use warnings ;

use lib '..' ;


use Test::More ;

use marc2neo4j ;

use MARC::Field ;

##########
# Test case 1: parse a basic 505 (non-extended) note
# with authors and the like

# Taken from UIUs catalog
# 001 	519763
# 035 	__ |a (OCoLC)ocm07272351
# 035 	__ |9 ACD-6419
# 245 	00 |a Whispers III / |c edited by Stuart David Schiff.
# 505 	0_ |a The dead line / Dennis Etchison -- Heading home / Ramsey Campbell -- King Crocodile / David Drake -- The door below / Hugh B. Cave -- Point of departure / Phyllis Eisenstein -- Firstborn / David Campton -- The horses of Lir / Roger Zelazny -- Woodland burial / Frank Belknap Long -- The river of night’s dreaming / Karl Edward Wagner -- Who nose what evil / Charles E. Fritch -- Comb my hair, please comb my hair / Jean Darling -- A fly one / Steve Sneyd -- The button molder / Fritz Leiber -- The final quest / William F. Nolan.

my $basic_505_field = MARC::Field->new( 505,
                                        '1','',
                                        'a' => q{The dead line / Dennis Etchison -- Heading home / Ramsey Campbell -- King Crocodile / David Drake -- The door below / Hugh B. Cave -- Point of departure / Phyllis Eisenstein -- Firstborn / David Campton -- The horses of Lir / Roger Zelazny -- Woodland burial / Frank Belknap Long -- The river of night’s dreaming / Karl Edward Wagner -- Who nose what evil / Charles E. Fritch -- Comb my hair, please comb my hair / Jean Darling -- A fly one / Steve Sneyd -- The button molder / Fritz Leiber -- The final quest / William F. Nolan.} ) ;

my @actual_work_hashes = marc2neo4j::parse_basic_contents( $basic_505_field ) ;


my @expected_work_hashes = (
    { title       => 'The dead line',
      responsible => 'Dennis Etchison',},
    { title => 'Heading home',
      responsible => 'Ramsey Campbell',},
    { title => 'King Crocodile',
      responsible => 'David Drake',},
    { title => 'The door below',
      responsible => 'Hugh B. Cave',},
    { title => 'Point of departure',
      responsible => 'Phyllis Eisenstein',},
    { title => 'Firstborn',
      responsible => 'David Campton',},
    { title => 'The horses of Lir',
      responsible => 'Roger Zelazny',},
    { title => 'Woodland burial',
      responsible => 'Frank Belknap Long',},
    { title => 'The river of night’s dreaming',
      responsible => 'Karl Edward Wagner',},
    { title => 'Who nose what evil',
      responsible => 'Charles E. Fritch' },
    { title => 'Comb my hair, please comb my hair',
      responsible => 'Jean Darling',},
    { title => 'A fly one',
      responsible => 'Steve Sneyd',},
    { title => 'The button molder',
      responsible => 'Fritz Leiber',},
    { title => 'The final quest',
      responsible => 'William F. Nolan'},
    ) ;

#use Data::Dumper ;

#print "actual: \n" ;
#print Dumper (\@actual_work_hashes ) ;

#print "expected: \n " ;
#print Dumper (\@expected_work_hashes ) ;

is_deeply( \@actual_work_hashes,
           \@expected_work_hashes ) ;



#     000 	01413cam a2200289 a 450
# 005 	20020415161540.0
# 008 	810226r1981 nyuaf 00001 eng
# 020 	__ |a 0385171625 : |c $9.95
# 039 	0_ |a 2 |b 3 |c 3 |d 3 |e 3
# 040 	__ |a DLC |c DLC |d UIU
# 050 	0_ |a PS648.F3 |b W46
# 082 	0_ |a 813/.0872/08 |2 19

# 250 	__ |a 1st ed.
# 260 	0_ |a Garden City, N.Y. : |b Doubleday, |c 1981.
# 300 	__ |a viii, 182 p., [4] p. of plates : |b ill. ; |c 22 cm.
# 500 	__ |a Stories originally published in Whispers magazine.
# 505 	0_ |a The dead line / Dennis Etchison -- Heading home / Ramsey Campbell -- King Crocodile / David Drake -- The door below / Hugh B. Cave -- Point of departure / Phyllis Eisenstein -- Firstborn / David Campton -- The horses of Lir / Roger Zelazny -- Woodland burial / Frank Belknap Long -- The river of night’s dreaming / Karl Edward Wagner -- Who nose what evil / Charles E. Fritch -- Comb my hair, please comb my hair / Jean Darling -- A fly one / Steve Sneyd -- The button molder / Fritz Leiber -- The final quest / William F. Nolan.
# 650 	_0 |a Fantasy fiction, American.
# 650 	_0 |a Horror tales, American.
# 650 	_0 |a Horror tales, English
# 650 	_0 |a Fantasy fiction, English.
# 700 	10 |a Schiff, Stuart David.
# 730 	_1 |a Whispers (Fayetteville, N.C.)
# Persistent link to this page: 	https://i-share.carli.illinois.edu/uiu/cgi-bin/Pwebrecon.cgi?DB=local&v4=1&BBRecID=519763


# 878657

#some short stories seem to have pattern of author name, short story
# tales
    
# 878657 - from uiuc catalog
# Sleep no more, |b twenty masterpieces of horror for the connoisseur, 
#505 	00 |t Count Magnus / |r M.R. James -- |t Cassius / |r Henry S. Whitehead -- |t The occupant of the room / |r Algernon Blackwood -- |t The return of the sorcerer / |r Clark Ashton Smith -- |t Johnson looked back / |r Thomas Burke -- |t The hand of the O’Mecca / |r Howard Wandrei -- |t "He cometh and he passeth by" / |r H.R. Wakefield -- |t Thus I refute Beelzy / |r John Collier -- |t The mannikin / |r Robert Bloch -- |t Two black bottles / |r Wilfred Blanch Talman -- |t The house of sounds / |r M.P. Shiel -- |t The cane / |r Carl Jacobi -- |t The horror in the burying ground / |r Hazel Heald -- |t The kennel / |r Maurice Level -- |t The yellow sign / |r Robert W. Chambers -- |t The black stone / |r Robert E. Howard -- |t Midnight express / |r Alfred Noyes -- |t A gentleman from Prague / |r Stephen Grendon -- |t The black druid / |r Frank Belknap Long -- |t The rats in the walls / |r H.P. Lovecraft.


# 000 	02781cam a22003011 45
# 001 	2087598
# 005 	20030808205627.0
# 008 	900530s1944 nyu 000 1 eng
# 010 	__ |a 44004879
# 035 	__ |a (OCoLC)ocm00588260
# 040 	__ |a DLC |c CWR |d DLC |d OCLCQ |d UIU
# 019 	__ |a 34586516
# 035 	__ |9 APV-8807
# 035 	__ |9 UC 18025717
# 050 	00 |a PZ1.W6795 |b Gr
# 049 	__ |a UIUU
# 100 	1_ |a Wise, Herbert A. |q (Herbert Alvin)
# 245 	10 |a Great tales of terror and the supernatural, |c ed. by Herbert A. Wise & Phyllis Fraser.
# 260 	__ |a New York : |b Random House, |c [1944]
# 300 	__ |a xix, 1080 p. |c 22 cm.
# 500 	__ |a "First printing."
# 505 	0_ |a Honore de Balzac / La Grande Breteche -- Edgar Allan Poe / The black cat -- The facts in the case of M. Valdemar -- Wilkie Collins / A terribly strange bed -- Ambrose Bierce / The boarded window -- Thomas Hardy / The three strangers -- W.W. Jacobs / The interruption -- H.G. Wells / Pollock and the Porroh man -- The sea raiders -- Saki(H.H. Munro / Sredni Vashtar -- Alexander Woollcott / Moonlight sonata -- Conrad Aiden / Silent snow, secret snow -- Dorothy L. Sayers / Suspicion -- Richard Connell / The most dangerous game -- Carl Stephenson Leiningen versus the ants -- Michael Arlen / The gentleman from America -- William Faulkner / A rose for Emily -- Ernest Hemingway / The killers -- John Collier / Back for Christmas -- Geoffrey Household / Taboo -- Edward Bulwer-Lytton / The haunters and the haunted or the house and the brain -- Nathaniel Hawthorne / Rappaccini’s daughter -- Charles Collins and Charles Dickens / The trial for murder -- Joseph Sheridan Le Fanu / Green tea -- Fitz-James O’Brien / What was it? -- Henry James / Sir Edmund Orme -- Guy de Maupassant / The horla -- Was it a dream? -- F. Marion Crawford / The screaming skull -- O. Henry / The furnished room -- M.R. James / Casting the runes -- Oh, whistle, and I’ll come to you, my lad -- Edith Wharton / Afterward -- W.W. Jacobs / The monkey’s paw -- Arthur Machen / The great God Pan -- Robert Hichens / How love came to professor Guildea -- Rudyard Kipling / The return of Imray -- "They" -- Edward Lucas White / Lukundoo -- F.F. Benson / Caterpillars -- Mrs. Amworth -- Algernon Blackwood / Ancient sorceries -- Confession -- Saki(H.H. Munro) / The open window -- Oliver Onions / The beckoning fair one -- Walter de la Mare / Out of the deep -- A.E. Coppard / Adam and Eve and pinch me -- E.M. Forster / The celestian omnibus -- Richard Middleton / The ghost ship -- Isak Dinesen / The sailor-boy’s tale -- H.P. Lovecraft / The rats in the walls -- The Dunwich horror.
# 650 	_0 |a Horror tales.
# 650 	_0 |a Short stories.
# 700 	1_ |a Wagner, Phyllis Cerf, |d 1915-
# 910 	__ |a rcp3254
# 994 	__ |a 02 |b UIU
# 910 	__ |a MARS
# Persistent link to this page: 	https://i-share.carli.illinois.edu/uiu/cgi-bin/Pwebrecon.cgi?DB=local&v4=1&BBRecID=2087598

#     Relevance: 	
# 000 	01531cam a2200205 i 450
# 001 	22018
# 005 	20020415161304.0
# 008 	800327s1980 nyu 00001 eng
# 020 	__ |a 0670256536
# 035 	__ |a (OCoLC)ocm06194868
# 035 	__ |9 AAC-3904
# 040 	__ |a DLC |c DLC |d m.c. |d IFK
# 050 	0_ |a PS648.H6 |b D37
# 082 	__ |a 813/.0872
# 245 	00 |a Dark forces : |b new stories of suspense and supernatural horror / |c edited by Kirby McCauley.
# 260 	0_ |a New York : |b Viking Press, |c 1980.
# 300 	__ |a xvi, 551 p. ; |c 25 cm.
# 505 	0_ |a The late shift, by Dennis Etchison.-The enemy, by Isaac Bashevis Singer-Dark angel, by Edward Bryant.-The crest of thirty-six, by Davis Grubb.-Mark ingestre: the customer’s tale, by Robert Aickman.-Where the summer ends, by Karl Edward Wagner.-The bingo master, by Joyce Carol Oates.-Children of the kingdom, by T.E.D Klein.-The detective of dreams, by Gene Wolfe.-Vengeance is, by Theodore Sturgeon.-The brood, by Ramsey Campbell.-The whistling well, by Clifford D. Simak.-The peculiar demesne, by Russell Kirk.-Where the stones grow, by Lisa Tuttle.-The night before Christmas, by Robert Bloch.-The stupid joke, by Edward Gorey.-A touch of petulance, by Ray Bradbury.-Lindsay and the red city blues, by Joe Haldeman.-A garden of blackred roses, by Charles L. Grant.-Owls hoot in the daytime, by Manly Wade Wellman.-Where there’s a will, by Richard Matheson and Richard Christian Matheson.-Traps, by Gahan Wilson.-The mist, by Stephen King.
# 650 	_0 |a Horror tales, American.
# 700 	10 |a McCauley, Kirby.
# Persistent link to this page: 	https://i-share.carli.illinois.edu/uiu/cgi-bin/Pwebrecon.cgi?DB=local&v4=1&BBRecID=22018

# Previous Next

# Print / Download / Email / Store
# Select Download Format
# Enter your email address:


#     Relevance: 	
# 000 	01318nam a2200217 i 450
# 001 	159599
# 005 	20020415161347.0
# 008 	751015s1975 nyu 00001 eng
# 020 	__ |a 0800876830 : |c $8.50
# 035 	__ |a (OCoLC)ocm01858022
# 035 	__ |9 AAR-0754
# 040 	__ |a DLC |c DLC |d UIU
# 050 	0_ |a PZ1 |b .T43 |a PR1309.H6
# 082 	__ |a 823/.0872
# 245 	04 |a The Thrill of horror : |b 22 terrifying tales / |c edited by Hugh Lamb.
# 260 	0_ |a New York : |b Taplinger Pub. Co., |c 1975.
# 300 	__ |a xiii, 207 p. ; |c 22 cm.
# 505 	0_ |a Haggard, H. R. Only a dream.--Lewis, L. A. The meerschaum pipe.--Ellis, A. E. the life-buoy.--Jackson, T. G., Sir. The lady of Rosemount.--Gawsworth, J. How it happened.--Bryusov, V. In the mirror.--Burnett, J. "Calling Miss Marker."--Donovan, D. A night of horror.--Rolt, L. T. C. The shouting.--Birkin, C. The happy dancers.--Hodgson, W. H. The weed men. Cowles, F. Eyes for the blind.--Wakefield, H. R. Mr. Ash’s studio.--Haining, R. Montage of death. Allen, G. Pallinghurst Barrow.--Scott, E. Randalls round.--Visiak, E. H. The skeleton at the feast. Medusan madness.--Benson, A. C. Out of the sea. Gilchrist, R. M. Witch in-grain.--Munby, A. N. L. The Tudor chimney.--James, M. R. The experiment.
# 650 	_0 |a Horror tales, English
# 650 	_0 |a Ghost stories, English.
# 700 	10 |a Lamb, Hugh.
# Persistent link to this page: 	https://i-share.carli.illinois.edu/uiu/cgi-bin/Pwebrecon.cgi?DB=local&v4=1&BBRecID=159599
done_testing() ;
