# Documentation de la base BISO

Ce dossier contient la documentation de la Base Indicateurs SOciaux (BISO) de la Drees. 

## Historique

BISO est l'héritière :

- des indicateurs sociaux départementaux (ISD)
- du panorama statistique cohésion sociale
- des indicateurs alimentant l'outil VILAS

Elle réunit les trois objets.

## Structure

La documentation se décompose en quatre fichiers selon leurs sources :

- [Indicateurs basés sur Finess](finess.md)
- [Indicateurs basés sur AS](as.md)
- [Indicateurs basés sur le RP](rp.md)
- [Indicateurs basés sur d'autres sources](autre.md)

Plus un fichier pour les éléments communs :
- [Sources statistiques et définitions](meta.md)

Un script permet leur agrégation, le rajout automatiques des années présentes dans biso ainsi que de la source, du code ISD, du code panorama et des libellés indiqués dans la documentation et la production d'un document pdf : 

- [Script d'agregation](R/insertion_lignes.R)