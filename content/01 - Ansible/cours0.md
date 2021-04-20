---
draft: true
---


## Réancrer les programmes dans leur **réalité d'exécution**

---

## Machines ain't smart. You are !

## Comment leur dire correctement quoi faire ?

---

# Infrastructure As Code

## Arrêtons de faire de l'adminsys adhoc

---

# Avantages : du contrôle

- Versionner le code avec git
--

- Tester les instrastructure pour plus de fiabilité
--

- Facilite l'intégration et le déploiement continus
  = vélocité
  = plusieurs versions par jours !

---


# Ansible, *langage* de programmation d'infrastructure

---

# Ansible 

--

- **Simple à mettre en œuvre** :
    - agentless
    - basé sur Python et SSH (présent sur linux souvent par défaut)
--

- **Versatile !!!**
--

- Pour configurer un simple serveur de dev jusqu'aux gros clusters de centaines de machines.
--

- Idempotence et versioning git accessible
--

- Syntaxe faite pour être lisible
--

- De plus en plus répandu ! c'est la **méga hype** !
--

- Sécurité car seulement SSH

---

## Pour coder durant cette formation

- **VSCode** : un éditeur puissant que vous connaissez un peu
- **Git et Framagit** : créer un dépôt, des commits et pousser ça sur internet !

---

class: impact

# Ansible

---

# Ansible

## Un logiciel pour configurer des machines
--
  
- Installer des logiciels (apt install)
--

- Modifier des fichier de configuration (/etc/…)
--

- Contrôler les services qui tournent (systemctl...)
--

- Gérer les utilisateurs et les permissions sur les fichiers
--

- etc.

---

# Ansible en image

.col-9[![](img/ansible_overview.jpg)]

---

 # Instrastructure As Code

## Du code qui contrôle l'état d'un serveur

Un peu comme un script bash mais :
--

- **Descriptif** : on peut lire facilement l'**état actuel** de l'infra
--

- **Idempotent** : on peut rejouer le playbook **plusieurs fois** pour s'assurer de l'état
--

- Du coup : playbook = état actuel de l'infra
--

- On contrôle ce qui se passe
--

- Assez différent de l'administration système *ad hoc* (= improvisation)


---
## Comparaison avec le bash (ou l'admin sys python)

- L'objectif d'Ansible est assez semblable au script Bash :
  - automatiser l'administration système
  - simple à mettre en œuvre : il suffit d'un fichier texte
  - très générique : basés sur des dépendances omniprésente sur les serveurs

- Ansible est une language de plus haut niveau basé sur des modules qui rendent les opérations plus facilement automatisables.

- ce language est concu spécialement pour manipuler la configuration des machines et exécuter des opérations de façon prédictible et reproductible.

---

# Infrastructure As Code

## Avantages

- On peut multiplier les machines (une machine ou 100 machines identiques c'est pareil).
--

- Git ! Gérer les versions de l'infrastructure et collaborer facilement comme avec du code.
--

- Tests fonctionnels (pour éviter les régressions/bugs)
--

- Pas de surprise = possibilité d'agrandir les clusters sans souci !
---

# Prérequis pour utiliser Ansible (minimal)

 1. Pouvoir se connecter en SSH sur la machine : **obligatoire** pour démarrer !!!
 2. **Python** disponible sur la machine à configurer : **facultatif** car on peut l'installer avec ansible

---

# Ansible en image

.col-9[![](img/ansible_overview.jpg)]

---




## Les forces d'Ansible

### Lisibilité (subjectif)

<!-- Image d'une ligne de commande bash -->

### Maintenabilité ?

---

### Déclaratif et idempotent

---

# DevOps et cloud

- Infrastructure as a Service (commercial et logiciel)
    - Amazon Web Services, Azure, Google Cloud, DigitalOcean
    - en local : Vagrant ou votre propre serveur de conteneurs.

- Plateform as a Service
    - Heroku, cluster Kubernetes

- Software as a Service
    - N'importe quelle web app
    - Adobe Creative Cloud est un bon exemple.

---

## Infrastructure as Code

- Une façon de définir une infrastructure dans un fichier descriptif et ainsi de créer et de provisionner dynamiquement les machines.

Un mouvement d'informatique lié au DevOps et au cloud :
- Ansible
- en particulier Terraform
- Vagrant pour le dev en local

---

# Ansible et DevOps

## Exprimer l'infrastructure et la configuration de façon centralisée

- Versioning

- Testing (unitaire, d'intégration, tests fonctionnels, canary testing)

-

## Rapprocher la production logicielle et la gestion de l'infrastructure

- Rapprocher la configuration de dev et de production (+ staging)

- Assumer le côté imprévisible de l'informatique en ayant une approche expérimentale

- Aller vers de l'intégration et du déploiement continu et automatisé.


## Inconvénients d'Ansible

- Relativement lent par défaut (subjectif), mais accélérable et parallélisable.
<!-- - Windows ? -->


## Opérations complexes, Ansible comme un language de programmation

- variables,
- facts,
- jinja,
- conditionals…


# Ansible et l'idempotence

- Une commande ou un playbook Ansible doivent pouvoir être relancés plusieurs fois sans introduire de nouveauté dans le système.

- Normalement une tâche exécutée une deuxième fois ne devrait pas renvoyer `changed`

- C'est la caractéristique d'Ansible qui permet d'avoir confiance lorsqu'on lance un playbook et donc d'aller vite dans les opérations (ne pas faire de vérification manuelle à chaque fois).

---