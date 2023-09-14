#!/bin/sh

set -o errexit -o pipefail

python -u -m redis_loader 
    gff \
       --genus Glycine \
       --species max \
       --strain Wm82 \
       --chromosome-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genome.gff3.gz \
       --gene-gff https://github.com/legumeinfo/microservices/raw/main/tests/data/genes.gff3.gz \
       --gfa https://github.com/legumeinfo/microservices/raw/main/tests/data/gfa.tsv.gz

# local file
# python -u -m redis_loader --load-type append gff --genus Medicago --species truncatula --strain R108_HM340 --gene-gff medtr.R108_HM340.gnm1.ann1.85YW.gcv_genes.gff3.gz --chromosome-gff glyma.58-161.gnm1.BW8J.gcv_genome.gff3 --gfa glyma.58-161.gnm1.ann1.HJ1K.legfed_v1_0.M65K.gfa.tsv

# fetch & load
# wget https://...
# python -u -m redis_loader ...
