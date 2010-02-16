<?php
/**
 * @file
 * @ingroup Maintenance
 */

if ( count( $argv ) != 3 ) {
	print <<<EOT
Read an article from the command line

Usage: php Mediawiki_getContent.php <MediawikiInstallationDir> <PageTitle>
Example: php Mediawiki_getContent.php /home/groups/r/rc/rcodeleveler/htdocs/wiki Main_Page

EOT;
	exit( 1 );
}

require_once( $argv[1].'/maintenance/commandLine.inc' );

$wgTitle = Title::newFromText( $argv[1] );
if ( !$wgTitle ) {
	print "Invalid title\n";
	exit( 1 );
}

$wgArticle = new Article( $wgTitle );

# Test if it exists
if( $wgArticle->getID() === 0 ) {
  exit( 1 );
} else {
  print $wgArticle->getContent();
  exit( 0 );
}
