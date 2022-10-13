#!/bin/bash

#Invoke conda to activate conda environments
source /home/usuario/anaconda3/etc/profile.d/conda.sh

#Create new folders to store assemblies
mkdir genomes

#DOWNLOAD ASSEMBLIES FROM SELECTED MICROORGANISMS (FULL GENOME REPRESENTATION)
while read line; do
    #Trim white space at the end of each row
    line_trim=`echo "${line::-1}"` 
    #echo -n "$line_trim" | wc -c #Count number of characters
    
    #Download ena codes for each assembly
    wget "https://www.ebi.ac.uk/ena/portal/api/search?result=assembly&query=assembly_title=%22*%20$line_trim*%22 AND genome_representation=%22full%22" #search assembly by clade name, be careful with white spaces at the end
    
    #Rename file containing ena codes for each assembly
    mv search* "${line}"_code_list

    #More examples of ena-ftp usage
    #https://www.ebi.ac.uk/ena/taxonomy/rest/scientific-name/Anaerostipes hadrus #get taxonomy
    #https://www.ebi.ac.uk/ena/portal/api/searchFields?result=assembly #query fields
    #https://www.ebi.ac.uk/ena/portal/api/search?result=assembly #assemblies available
    #https://www.ebi.ac.uk/ena/portal/api/search?result=assembly&query=assembly_level="contig" #assemblies available at contig level
    #https://www.ebi.ac.uk/ena/portal/api/search?result=assembly&query=assembly_title="ASM87613v1 assembly for Anaerostipes hadrus" #search assembly by full title
    #https://www.ebi.ac.uk/ena/portal/api/search?result=assembly&query=strain="PEL 85" #search assembly by strain
    #https://www.ebi.ac.uk/ena/portal/api/search?result=assembly&query=genome_representation="full" #search assembly by completeness

    #Read file containing ena codes for each assembly
    while read line2; do
        #Get ena codes for all assemblies
        code=$(echo $line2 | awk '{print $1}')
        #Select only those lines containing ena codes and download xml search data
        if [[ ! $code =~ "accession" ]] ; then wget "https://www.ebi.ac.uk/ena/browser/api/xml/"${code}""; fi
        #Add "temp_" tag to temportary files containing assembly codes and metadata
        mv "${code}" temp_"${code}"
        #Create a new variable called "ftp_input" to read temporary files
        ftp_input="temp_"${code}""
        #Select the line containing the ftp link to the assembly fasta file
        ftp_link=$(cat $ftp_input | head -n $i | tail -n 1)
        #Clean the line containing the ftp link to the assembly fasta file
        ftp_link=$(grep -n "ftp.*fast" $ftp_input)
        ftp_link="${ftp_link//"</URL>"/}"
        ftp_link="${ftp_link//*>/}"
        #Download the assembly fasta file through ftp
        wget $ftp_link
        #Decompress the assembly fasta file
        gzip -d *.gz
        #Rename the assembly fasta file to include ncbi code and genus
        mv *.fasta "${line}"_"${code}".fasta
        #Move assembly fasta file to "genomes" folder
        mv *fasta genomes/ 
    done < "${line}"_code_list
done < taxa_list.txt

#Remove temportary files containing assembly codes and metadata
rm -rf temp_*
#Remove temportary files containing assembly code list
rm -rf *_code_list




#Finish
