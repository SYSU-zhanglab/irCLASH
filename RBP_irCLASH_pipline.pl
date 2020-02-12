#! /bin/env perl
   use strict;
   use autodie;
   use 5.010;
   use Getopt::Long;
   my($in,$help);
   GetOptions("in=s"=>\$in,"help"=>\$help);
   $in=$in?$in:'./';
   if($help){
     print "The pipline aims to search hyrid reads for irCLASH data!\n\n
     --in:the work path;\n
     --help:the help!\n\n";
  }elsif($in){
     $in=substr($in,-1) eq '/'?$in:$in.'/';
     opendir IN,$in;
     foreach(readdir IN){
         #s/fq$/fastq/g;
       if(m/_3_dis_barcodes_b15_clean-tags.fa$/){
         my $seq_file=$_;
         my $kes=$_;
         $kes=~s/_3_dis_barcodes_b15_clean-tags.fa$//g;
         `mkdir $kes`;
         my $wpath=$in.$kes.'/';
         my $r_name_3=$in.$kes.'_3_dis_barcodes_b15_clean-tags.fa';
         my $mapping_RNA_bowtie=$wpath.$kes.'_1_bowtie1_mapping_all_RNAs.sam';
         my $log_2=$wpath.$kes.'_1_bowtie1_mapping_all_RNAs.log';
         #Step 4, mapping to genome by bowtie1, the strict parameters;
         `nohup bowtie -f -S -p 30 -v 3 -k 10 --best --strata all_RNAs_bowtie_index $r_name_3 $mapping_RNA_bowtie>$log_2`;
         my $n_seq_RNAs=$wpath.$kes.'_1_unmapped_all_RNAs_reads.fa';#the unmapped genome nonalu tags by bowtie1;
         #Step 4, extract the CLIP result;
         `perl ext_unmapping_RNAs_reads --in $mapping_RNA_bowtie --reads $r_name_3 --out $n_seq_RNAs`;
         my $mapping_genome_bowtie=$wpath.$kes.'_2_bowtie1_mapping_genome.sam';
         my $log_3=$wpath.$kes.'_2_bowtie1_mapping_genome.log';
         #Step 4, mapping to genome by bowtie1, the strict parameters;
         `nohup bowtie -f -S -p 30 -v 3 -k 10 --best --strata genome_bowtie_index $n_seq_RNAs $mapping_genome_bowtie>$log_3`;
         my $n_seq_genome=$wpath.$kes.'_2_unmapped_genome_reads.fa';#the unmapped genome nonalu tags by bowtie1;
         #Step 4, extract the CLIP result;
         `perl ext_unmapping_RNAs_reads --in $mapping_genome_bowtie --reads $n_seq_RNAs --out $n_seq_genome`;

         
         my $star_mapping_1_prefix=$wpath.$kes.'_3_STAR_mapping_';#the output prefix for STAR mapping;
         #Step 5, STAR mapping to genome, with EndToEnd parameters, with chimeric 7 nts;
         `STAR --genomeDir genome_star_index --runThreadN 30 --readFilesIn $n_seq_genome --outFileNamePrefix $star_mapping_1_prefix --outSAMprimaryFlag AllBestScore --outSAMattributes All --outFilterMultimapNmax 100 --outFilterMismatchNmax 3 --alignEndsType EndToEnd --outSAMunmapped Within --chimSegmentMin 7 --alignIntronMin 4`;
         #Step 6, extract uniquely mapping results;
         my $star_map_res=$star_mapping_1_prefix.'Aligned.out.sam';
         my $unique_hybrid=$wpath.$kes.'_unique_hybrid_reads_mapping_res.sam';
         my $multi_hybrid=$wpath.$kes.'_multi_hybrid_reads_mapping_res.sam';
         my $map_reads=$wpath.$kes.'_STAR_map_reads.fa';
         my $unmap_reads=$wpath.$kes.'_STAR_unmap_reads.fa';

         `perl ext_unique_multiple_hybrids --in $star_map_res --unique $unique_hybrid --multi $multi_hybrid --map $map_reads --unmap $unmap_reads --reads $n_seq_genome`;
         my $recom_bowtie2_res=$wpath.$kes.'_STAR_unmap_bowtie2.sam';
         my $recom_bowtie2_log=$wpath.$kes.'_STAR_unmap_bowtie2.log';
         `nohup bowtie2 --very-sensitive-local -f -p 36 -k 100 -x genome_bowtie2_index -U $unmap_reads -S $recom_bowtie2_res>$recom_bowtie2_log`;
         my $recom_reads=$wpath.$kes.'_STAR_unmap_recombined_reads.fa';
         `perl ext_clash_reads --in $recom_bowtie2_res --seq $unmap_reads --out $recom_reads`;
         my $recom_star_prefix=$wpath.$kes.'_recombined_STAR_';
         `STAR --genomeDir genome_star_index --runThreadN 30 --readFilesIn $recom_reads --outFileNamePrefix $recom_star_prefix --outSAMprimaryFlag AllBestScore --outSAMattributes All --outFilterMultimapNmax 100 --outFilterMismatchNmax 3 --alignEndsType EndToEnd --outSAMunmapped Within --chimSegmentMin 7 --alignIntronMin 4`;
         my $recom_star_map_res=$recom_star_prefix.'Aligned.out.sam';
         my $recom_map=$wpath.$kes.'_recombined_STAR_mapped_reads.fa';
         my $recom_unmap=$wpath.$kes.'_recombined_STAR_unmapped_reads.fa';
         my $recom_unique=$wpath.$kes.'_recombined_STAR_unique_hybrid_reads';
         my $recom_multi=$wpath.$kes.'_recombined_STAR_multiple_hybrid_reads';
         `perl div_recombined_Hybrid_reads --in $recom_star_map_res --sam $recom_bowtie2_res --seq $recom_reads --reads $unmap_reads --map $recom_map --unmap $recom_unmap --unique $recom_unique --multi $recom_multi`;
         my $unique_hybrid_merge=$wpath.$kes.'_unique_Hybrid_result_merge.sam';
         `perl merge_hybrid_res --ina $unique_hybrid --inb $recom_unique --out $unique_hybrid_merge`;
         my $multi_hybrid_merge=$wpath.$kes.'_multiple_Hybrid_result_merge.sam';
         `perl merge_hybrid_res --ina $multi_hybrid --inb $recom_multi --out $multi_hybrid_merge`;
        }
      }
         closedir IN; 
    }
