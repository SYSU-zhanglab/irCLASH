#! /bin/env perl
   use strict;
   use 5.010;
   use autodie;
   use Getopt::Long;
   my($in,$out,$help,$cutoff,$min);
   GetOptions("in=s"=>\$in,"out=s"=>\$out,"cutoff=s"=>\$cutoff,"help"=>\$help,"min=s"=>\$min);
   if($in and $out and $cutoff){
     open IN,'<',$in;
     open OUT,'>',$out;
     $min=$min?$min:10;
     my $id;
     while(<IN>){
       chomp;
       if(substr($_,0,1) eq '>'){
         $id=$_;
      }elsif($_ !~ m/N/g){
         if(length($_)>$cutoff){
           $id=$id.':'.substr($_,0,$cutoff);
           my $seq=substr($_,$cutoff);
           print OUT $id."\n".$seq."\n" if length($seq)>=$min;
        }
      }
    }
     close IN;
     close OUT;
   }elsif($help){
      say"This script aims to discard the barcodes for the CLIP tags\n
      --in:the input file;\n
      --out:the result file;\n
      --cutoff:the length of barcodes in 5';\n
      --min:the min length of clean tag, the default if 10;\n
      --help:the help!\n";
   }else{
      print "Please read the help!\n";
   }
