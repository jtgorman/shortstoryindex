#!/usr/bin/env perl

use strict ;
use warnings ;

use lib '..' ;


use Test::More ;

use marc2neo4j ;

use MARC::Field ;

use ParseTwoFSM qw( parse );


run_test_cases() ;
done_testing() ;


sub run_test_cases {

    run_basic_contents_pattern1() ;
    run_basic_contents_pattern2() ;
}


 
    
    

##########
# Test case 1: parse a basic 505 (non-extended) note
# with authors and the like
# following a title / author -- form

# Taken from UIUs catalog
# 001 	519763
# 035 	__ |a (OCoLC)ocm07272351
# 035 	__ |9 ACD-6419
# 245 	00 |a Whispers III / |c edited by Stuart David Schiff.
# 505 	0_ |a The dead line / Dennis Etchison -- Heading home / Ramsey Campbell -- King Crocodile / David Drake -- The door below / Hugh B. Cave -- Point of departure / Phyllis Eisenstein -- Firstborn / David Campton -- The horses of Lir / Roger Zelazny -- Woodland burial / Frank Belknap Long -- The river of night’s dreaming / Karl Edward Wagner -- Who nose what evil / Charles E. Fritch -- Comb my hair, please comb my hair / Jean Darling -- A fly one / Steve Sneyd -- The button molder / Fritz Leiber -- The final quest / William F. Nolan.

sub run_basic_contents_pattern1 {

    my $basic_505_field = MARC::Field->new( 505,
                                            '1','',
                                            'a' => q{The dead line / Dennis Etchison -- Heading home / Ramsey Campbell -- King Crocodile / David Drake -- The door below / Hugh B. Cave -- Point of departure / Phyllis Eisenstein -- Firstborn / David Campton -- The horses of Lir / Roger Zelazny -- Woodland burial / Frank Belknap Long -- The river of night’s dreaming / Karl Edward Wagner -- Who nose what evil / Charles E. Fritch -- Comb my hair, please comb my hair / Jean Darling -- A fly one / Steve Sneyd -- The button molder / Fritz Leiber -- The final quest / William F. Nolan.} ) ;

    my @actual_work_hashes = marc2neo4j::parse_basic_contents( $basic_505_field ) ;
    
    
    my @expected_work_hashes = (
        { title       => 'The dead line',
          responsible => ['Dennis Etchison',]},
        { title => 'Heading home',
          responsible => ['Ramsey Campbell'],},
        { title => 'King Crocodile',
          responsible => ['David Drake'],},
        { title => 'The door below',
          responsible => ['Hugh B. Cave'],},
        { title => 'Point of departure',
          responsible => ['Phyllis Eisenstein'],},
        { title => 'Firstborn',
          responsible => ['David Campton'],},
        { title => 'The horses of Lir',
          responsible => ['Roger Zelazny'],},
        { title => 'Woodland burial',
          responsible => ['Frank Belknap Long'],},
        { title => 'The river of night’s dreaming',
          responsible => ['Karl Edward Wagner'],},
        { title => 'Who nose what evil',
          responsible => ['Charles E. Fritch'] },
        { title => 'Comb my hair, please comb my hair',
          responsible => ['Jean Darling'],},
        { title => 'A fly one',
          responsible => ['Steve Sneyd'],},
        { title => 'The button molder',
          responsible => ['Fritz Leiber'],},
        { title => 'The final quest',
          responsible => ['William F. Nolan']},
    ) ;

    is_deeply( \@actual_work_hashes,
               \@expected_work_hashes ) ;
}
##########
# Test case 2: parse a basic 505 (non-extended) note
# with authors
#
# pattern of
# author name . title --
#
# note this test case is based off the original record, but
# with corrctions (this is why free form metdata entry w/o validation is
# a bad idea....


sub run_basic_contents_pattern2 {


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
# 505 	0_ |a Haggard, H. R. Only a dream.--Lewis, L. A. The meerschaum pipe.--Ellis, A. E. the life-buoy.--Jackson, T. G., Sir. The lady of Rosemount.--Gawsworth, J. How it happened.--Bryusov, V. In the mirror.--Burnett, J. "Calling Miss Marker."--Donovan, D. A night of horror.--Rolt, L. T. C. The shouting.--Birkin, C. The happy dancers.--Hodgson, W. H. The weed men.--Cowles, F. Eyes for the blind.--Wakefield, H. R. Mr. Ash’s studio.--Haining, R. Montage of death.--Allen, G. Pallinghurst Barrow.--Scott, E. Randalls round.--Visiak, E. H. The skeleton at the feast. Medusan madness.--Benson, A. C. Out of the sea.--Gilchrist, R. M. Witch in-grain.--Munby, A. N. L. The Tudor chimney.--James, M. R. The experiment.
# 650 	_0 |a Horror tales, English
# 650 	_0 |a Ghost stories, English.
# 700 	10 |a Lamb, Hugh.
# Persistent link to this page: 	https://i-share.carli.illinois.edu/uiu/cgi-bin/Pwebrecon.cgi?DB=local&v4=1&BBRecID=159599


    my $basic_505_field = MARC::Field->new( 505,
                                            '0','',
                                            'a' => q{Haggard, H. R. Only a dream.--Lewis, L. A. The meerschaum pipe.--Ellis, A. E. the life-buoy.--Jackson, T. G., Sir. The lady of Rosemount.--Gawsworth, J. How it happened.--Bryusov, V. In the mirror.--Burnett, J. "Calling Miss Marker."--Donovan, D. A night of horror.--Rolt, L. T. C. The shouting.--Birkin, C. The happy dancers.--Hodgson, W. H. The weed men.--Cowles, F. Eyes for the blind.--Wakefield, H. R. Mr. Ash’s studio.--Haining, R. Montage of death.--Allen, G. Pallinghurst Barrow.--Scott, E. Randalls round.--Visiak, E. H. The skeleton at the feast. Medusan madness.--Benson, A. C. Out of the sea.--Gilchrist, R. M. Witch in-grain.--Munby, A. N. L. The Tudor chimney.--James, M. R. The experiment.} ) ;
    
    my @actual_work_hashes = marc2neo4j::parse_basic_contents( $basic_505_field ) ;

    use Data::Dumper ;
    
    #print Dumper( \@actual_work_hashes ) ;
   # print "\n\n\n\n" ;
# ugh, trimming periods could be an issue...put on to do later..
# definitely need to consider adding something to the parsing process
# that will "call out" when it runs into weirdness so a human can parse...
#
# It seems though that hte "author first" form might be used when
# there's multiple stories by the same author?
#
# idea, always flatten to title/authors hash,

my @expected_work_hashes = (
    { responsible => ['H. R. Haggard'],
      title       => 'Only a dream',},
    { responsible  => ['L. A. Lewis'],
      title        => 'The meerschaum pipe', },
    { responsible  => ['A. E. Ellis'],
      title => 'the life-buoy',},
    { responsible  => ['Sir T. G. Jackson'],
      title        => 'The lady of Rosemount',},
    { responsible  => ['J. Gawsworth'],
      title => 'How it happened', },
    { responsible  => ['V. Bryusov'],
      title => 'In the mirror', },
    {responsible  => ['J. Burnett'],
     # well, crud, this is a tricky one...
     # for now going to ignore for now, but
     # good example of confusing ...
     title => q{"Calling Miss Marker},},
    {responsible  => ['D. Donovan'],
     title => 'A night of horror',},
    { responsible  => ['L. T. C. Rolt'],
      title => 'The shouting'},
    { responsible  => ['C. Birkin'],
      title => 'The happy dancers'},
    { responsible  => ['W. H. Hodgson'],
      title=> 'The weed men',},
    { responsible  => ['F. Cowles'],
      title => 'Eyes for the blind' },
    { responsible  => ['H. R. Wakefield'],
       title => q{Mr. Ash’s studio} },
    { responsible  => ['R. Haining'],
      title => 'Montage of death'},
    { responsible  => ['G. Allen'],
      title => 'Pallinghurst Barrow'},
    { responsible  => ['E. Scott'],
      title => 'Randalls round' },
    { responsible  => ['E. H. Visiak'],
      title => 'The skeleton at the feast'},
    { responsible  => ['E. H. Visiak'],
      title => 'Medusan madness'},
    { responsible  => ['A. C. Benson'],
      title => 'Out of the sea'},
    { responsible  => ['R. M. Gilchrist'],
      title => 'Witch in-grain'},
    { responsible  => ['A. N. L. Munby'],
      title => 'The Tudor chimney' },
    { responsible  => ['M. R. James'],
      title => 'The experiment' }
) ;
    
    is_deeply( \@actual_work_hashes,
               \@expected_work_hashes ) ;

}
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


# extended notes
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
