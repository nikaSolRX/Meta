## Prérequis

- Julia 1.x
- Packages Julia (installer si besoin) :
  ```julia
  import Pkg
  Pkg.add(["JuMP","GLPK","PyPlot"])
  ```
- Fichiers d'instances disponibles dans `dat/` ou `dat2/`.

## Structure du projet

```
PenetRodriguesEI3/
├── dat/                     # Instances SPP
├── doc/                     # Documentation / notes
├── res/
│   ├── datas/               # fichier statistique généré par test_instances.jl
│   ├── graphs/              # Graphiques générés
│   └── resultats_tabou.csv
└── src/
    ├── algoAmelioration.jl  # Recherche Tabou
    ├── algoconstru.jl       # Construction initiale (SPP)
    ├── getfname.jl
    ├── livrableEI3.jl       # Point d'entrée utilisateur (contient tabouSPP())
    ├── loadSPP.jl
    ├── main.jl
    ├── setSPP.jl
    └── test_instances.jl
```

## Fonctions/points d'entrée principaux

- `tabouSPP(instance::String, iterations::Int; taille_tabou::Int = default)`  
  Fonction définie dans `src/livrableEI3.jl`. Lance la recherche tabou sur `instance` pendant `iterations`. Si `taille_tabou` n'est pas fourni, la valeur par défaut est calculée (`k ÷ 2` où `k` = taille solution initiale).

- `SPP(C, A)` dans `src/setSPP.jl` : construction gloutonne initiale.

- `tabou_upgrade(...)` dans `src/algoAmelioration.jl` : corps de la recherche tabou (amélioration locale, intensification/diversification, tracés).

## Exemples d'utilisation

1. Depuis le REPL Julia (dans le dossier racine du projet) :
```julia
cd("c:/Users/Loufox/Documents/Github Random/Meta/PenetRodriguesEI3")
include("src/livrableEI3.jl")
# appel avec taille tabou par défaut (k ÷ 2)
tabouSPP("dat/pb_1000rnd0300.dat", 600)
# appel en spécifiant la taille tabou
tabouSPP("dat/pb_1000rnd0300.dat", 600, 20)
```

2. Pour générer le fichier `synthese_resultats.png` () :
```julia
include("src/test_instances.jl")
#lancer la fonction sur tous les fichiers .dat d'un dossier spécifié 
#(ici le dossier /dat)
test_instances_csv("dat")
```
(Assurez‑vous que `main.jl` accepte des arguments ou appelle `tabouSPP`.)

## Emplacement des sorties

- Graphiques PNG : `res/graphs/`
- Résultats tabous agrégés : `res/resultats_tabou.csv`
- Données intermédiaires : `res/datas/`

Si un répertoire manque, le script crée automatiquement `res/` ou `res/graphs/` avant d'enregistrer.

## Debug / conseils pratiques

- Vérifier le répertoire courant du REPL : `pwd()`. Changer avec `cd("chemin")` pour accéder au répertoire actuel de ce **READ ME**.
- Si PyPlot / Matplotlib lève des erreurs lors de `savefig`, vérifier que `res/graphs/` existe et que le nom d'instance ne contient pas de caractères invalides.
- Pour le logging console compact : l'algorithme imprime une ligne par itération avec `Itération | z_curr | z_best | alpha | <mode>`.

## Auteurs

- Auteur : Rodrigues & Penet  