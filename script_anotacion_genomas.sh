#!/bin/bash

#Determine ORFs using prodigal to perform functional domain annotation
#In: fasta, out: orfs.gff (open reading frame), de 6 marcos posibles en cualquier contigs.
for sequence in genomes/*.fa*; do (sequence_name="${sequence//*"/"/}" && sequence_name="${sequence_name//.*/}" && prodigal -f gff -a "${sequence_name}"_aaORFs.fasta -i $sequence -o "${sequence_name}"_ORFs.gff -d "${sequence_name}"_ORFs.gff); done
#Store prodigal results in different folders
mkdir prodigal_results
mv *ORFs* prodigal_results/

#Annotate genomes - general functional domain annotation

#Necesito descargar las bases de datos: pfam con los archivos hmm y cazy.
#Archivos hmm vienen de Hummer (web), utilizando modelos markow escondidos (hindden markov Models; profile hmms) para el analisis de secuencias
#Se busca en bd de secuencias, secuencias homologas y para hacer el alineamiento.
#Normalmente se utiliza con bd de perfile como pfam  y se puede trabajar con secuencias de consulta (query) tipo BLAST, como bd phmmer o jackhummer
#HMMER está diseñado para detectar homólogos remotos con la mayor sensibilidad posible, basándose en la solidez de sus modelos de probabilidad subyacentes.

#BUSQUEDA TUTORIA: The file you downloaded contains sequences. You probably want the file with HMMs.
    #http://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/Pfam-A.hmm.gz
    #Probe descargar primero hmmer con comando rapido en bioconda: http://hmmer.org/documentation.html -> conda install -c bioconda hmmer
    #Descargue del primer enlace la base de datos: Pfam-A.hmm.gz
    #pasos: gzip -d Pfam-A.hmm.gz

#le cambio al comando la direccion de la base de datos
#parallel -j 20 'hmmsearch --cpu 1 -E 1e-10 --tblout {/.}_pfam_annotation_tbl -o {/.}_pfam_annotation /database/dir/Pfam-A.hmm {}' ::: prodigal_results/*_aaORFs.fasta
#parallel es run programs in parallel
parallel -j 20 'hmmsearch --cpu 1 -E 1e-10 --tblout {/.}_pfam_annotation_tbl -o {/.}_pfam_annotation ./Pfam-A.hmm {}' ::: prodigal_results/*_aaORFs.fasta


#Store hmmer outputs in a different folder
mkdir hmmer_results
mkdir hmmer_results/annotation
mkdir hmmer_results/tbl
mv *_pfam_annotation hmmer_results/annotation/
mv *_pfam_annotation_tbl hmmer_results/tbl/

#Annotate genomes - carbohydrate active enzymes
#Tutorial: instalacion del paquete en bioconda y las bases de datos necesariias: https://github.com/linnabrown/run_dbcan
    #3. database installation test -d db || mkdir db
    #If you use python package or docker, you don't need to download Prodigal because they includes these denpendencies.
    #Otherwise we recommend you to install and copy them into /usr/bin as system application or add their path into system envrionmental profile.
    #DATABASES Installation (he elegido solo cazy; hay un listado entero)
        #conda activate run_dbcan
        #(run_dbcan) test -d db || mkdir db
        #(run_dbcan) cd db && wget http://bcb.unl.edu/dbCAN2/download/Databases/V11/CAZyDB.08062022.fa && diamond makedb --in CAZyDB.08062022.fa -d CAZy
        #y las descargo todas en la carpeta creada de db con el && wget etc... 
#CAMBIO POSICION DE LA BASE DE DATOS CAZY
#parallel -j 20 'run_dbcan {} --db_dir /database/dir/cazy_db prok --out_dir {/.}' ::: genomes/*.fa*
parallel -j 20 'run_dbcan {} --db_dir /home/ackhmoussachraiteh/Documents/TFM/Genoma/db prok --out_dir {/.}' ::: genomes/*.fa*

#Store cazy outputs in a different folder
mkdir cazy_results
mv *_GCA_* cazy_results/
#Create folder to store functional domains results in csv
mkdir cazy_functional_domains
for folder in cazy_results/*/ ; do (cd "$folder" && code=$(basename "$PWD") && mv hmmer.out "${code}"_hmmer.csv); done
cp cazy_results/*/*_hmmer.csv cazy_functional_domains
#Check all files were correctly copied
ls cazy_functional_domains/*_hmmer.csv | wc -l




#Finish
