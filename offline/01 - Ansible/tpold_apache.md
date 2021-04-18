---
draft: true
---

TP1 : Installation de quelques serveurs Apache avec Ansible

Cours d'introduction sur Ansible
--------------------------------

Mettre en place son cluster
---------------------------

On va créer deux machines virtuelles pour notre cluster en plus de votre
machine de travail sur Ubuntu Desktop (que nous appellerons par la suite "master").

1.  Importons deux machines Ubuntu Server depuis le disque de partage. Lors de l'import, donnez-leur un nom identifiable, comme "node1" et "node2". Lors de l'import de la deuxième machine, sélectionnez l'option "Générer de nouvelles adresses MAC pour toutes les interfaces réseau" pour ne pas avoir de problèmes de réseau, comme ceci :
<br />
<img src="tp1_images/importvm2.png" width="500px">
<br />

2.  Activez le DHCP sur le réseau « Host-only » de VirtualBox :
    Dans Virtualbox : Fichier > Gestionnaire de réseau hôte...
3.  Cochez la case pour activer le DHCP pour le réseau créé par défaut par VirtualBox, comme ceci, et notez bien son nom (ici : "VirtualBox Host-Only Ethernet Adapter #2") :
<br />
<img src="tp1_images/reseauvm2.png" width="500px">
<br />

4.  Éditez les réseaux de chacune des trois machines pour les mettre dans le réseau que l'on vient de configurer. Pour chaque machine : Machine > Configuration... > Réseau. En éteignant les machines si besoin, activez deux interfaces, l'une avec "NAT" et l'autre avec "Réseau privé hôte" en indiquant le réseau vu précédemment (ici : "VirtualBox Host-Only Ethernet Adapater #2") :
<br />
<img src="tp1_images/reseauvm3.png" width="500px">

<img src="tp1_images/reseauvm4.png" width="500px">
<br />

La première interface sert à donner Internet facilement à notre machine, la deuxième sert à mettre toutes les machines sur un réseau commun.

5.  Lancez les deux nodes et votre machine Ubuntu Desktop qui sera notre
    master Ansible
6.  Dans chacune des machines, trouvez un terminal et lancez `**ip a**` ou
    `**ifconfig**`
7.  Relevez les adresses IP des trois machines et écrivez-les sur papier :

-   node 1 : 
-   node 2 : 
-   master : 

7. L'utilisateur par défaut des nodes est `admin` avec le mot de passe `password`.
8.  Vérifiez que vous pouvez pinguer les autres machines du cluster :
    `ping <ip>`



Configurer SSH et lancer une commande Ansible ad hoc
----------------------------------------------------

SSH est déjà installé sur les nœuds car Ubuntu Server embarque SSH par
défaut. Cependant Ubuntu Desktop ne l'incorpore pas.

1.  Dans le master (Desktop) installez **git, curl, ssh** et **sshpass**.
    (Sur Ubuntu, comme sous Mint ou Debian : `sudo apt
    install <paquet>`)
2.  Vérifiez que vous pouvez vous connecter en SSH sur chacun des nœuds
    depuis le master en utilisant :
    - login : **admin**
    - password : **password**
3. Revenez sur le master en fermant la connexion SSH avec `exit` : assurez-vous que vous êtes de nouveau sur le master en lançant la commande `hostname`.
3.  Créez un dossier **TP1** et à l'intérieur ajoutez un fichier
    **ansible.cfg** avec le contenu :
    ```ini
    [defaults]
    inventory = ./hosts.ini
    host_key_checking = False
    ```
4.  Créez ensuite un fichier **hosts.ini** contenant la liste des nœuds à
    configurer avec Ansible (l'inventaire des machines) et remplacez ce qu'il y a à l'intérieur des chevrons par les vraies informations (**et supprimez les chevrons**) :
    ```ini
    [nodes]
    node1 ansible_host=<ip>
    node2 ansible_host=<ip>
    [nodes:vars]
    ansible_user=<user>
    ansible_password=<password>
    ansible_become_password=<sudo password>
    ```

5. Nous allons installer Ansible à partir du dépôt officiel d'Ansible :
`sudo add-apt-repository ppa:ansible/ansible`
`sudo apt update`
`sudo apt install --reinstall ansible`
Vérifiez que vous possédez Ansible 2.8 en faisant un `ansible --version`.


6.  Pour vérifier que tout fonctionne jusqu'ici nous allons lancer le
    module **ping** d'Ansible qui sert à contacter les nœuds de
    l'inventaire pour vérifier la configuration. Une fois dans le
    dossier TP1 lancez : **ansible nodes -m ping**. Vous devriez obtenir
    deux **FAILURE** avec le message **python not found**. Ceci indique
    qu'Ansible a bien réussi à se connecter aux nœuds mais que Python
    n'a pas pu être trouvé et donc le module **ping** n'a pas été
    exécuté.
7.  A ce stade vous pourriez vous connectez manuellement en SSH sur
    chaque nœud pour installer python, mais nous allons utiliser Ansible
    pour cela. Un des seuls modules exécutables sans Python et qui est
    souvent utilisé pour préconfigurer les machines est le module
    **raw**. Il permet simplement de lancer une commande Unix simple.
    Par exemple pour installer Python sur le node1 :
    ```bash
    ansible node1 --become -m raw -a 'apt install -y python-minimal'
    ```
    L'option "--become" est nécessaire car c'est elle qui autorise Ansible à faire un "sudo" s'il en a besoin, comme lors de l'exécution d'une commande `apt`.

8.  A ce stade si vous relancez la commande ping précédente vous devriez
    voir un succès sur le node1, et un échec sur le node où Python n'est pas installé.

<!-- Cours sur l'organisation d'un playbook, les modules et la syntaxe yaml.
----------------------------------------------------------------------- -->

Créer un premier playbook
-------------------------




1.  Créer un fichier **ping.yml**. À l'intérieur ajoutez :


```yaml
---
- hosts: nodes

  tasks:
  - ping:
```

2.  Pour lancer ce playbook, exécutez dans le dossier TP1 :

    `ansible-playbook ping.yml`

    Vous devriez obtenir le même résultat qu'à la question 16 (un
    succès sur node1 et un échec sur node2 avec `python not found`).

3.  Pour supprimer cette erreur, installez Python sur le deuxième nœud avec Ansible.
    Ensuite, pour autoriser Ansible à devenir super-utilisateur (équivalent de `sudo`) ajoutez en dessous de **hosts : nodes**, les deux lignes suivantes
    (alignées avec hosts). :

    ```yaml
    become: yes
    gather_facts: False
    ```
    La ligne avec `gather_facts` sert à nous faire gagner du temps dans l'exécution des commandes, car nous n'avons pas besoin des `facts` que collecte Ansible pour l'instant.

4.  Dans le répertoire de votre projet, ajoutez un fichier **.gitignore** contenant simplement `*.retry`.
    Ce fichier sert à indiquer à **git** d'ignorer les fichier
    **.retry** produits automatiquement par Ansible à chaque échec. Tout
    projet git devrait contenir un fichier **.gitignore** pour éviter
    d'être pollué par les fichiers inutiles.
5.  Nous allons créer un dépôt pour envoyer le contenu du dossier TP1 dans un projet Git (avec **git init, add, commit)**
    1. Dans le bon répertoire (soit à la racine de votre projet, dans le dossier TP1), `git init` pour initialiser le projet Git.
    2. `git add .` pour ajouter tous les fichiers du repértoire courant (vérifiez : êtes-vous bien dans le bon répertoire ?)
    3. `git commit -m "<votre message explicatif : que font vos modifications associées à ce commit ?>"`
6.  Poussez-le sur **gitlab.com* :
    1. Créez votre compte sur le site
    2. Puis créez un nouveau projet sur le site
    3. `git remote add origin <url du projet>` sur votre ordinateur pour dire que le projet Git en local doit être connecté à l'url distante du projet sur Gitlab (à trouver sur le site). N'oubliez pas de rajouter le nom standardisé (ou *slug*) du projet à la fin de l'URL s'il n'y figure pas !
    5. Configurez votre prénom et nom : `git config --global user.name "FIRST_NAME LAST_NAME"`
    6. Configurez votre addresse email : `git config --global user.email "MY_NAME@example.com"`
    7.   Enfin, vous pouvez normalement faire votre premier `push`, en identifiant la branche d'origine avec `git push --set-upstream origin master`
    8.   Vérifiez sur Gitlab que le `push` des modifications a bien marché

***A l'avenir, pour pouvoir faire `push` sur Git, il suffira de répéter les étapes `git add .`, `git commit -m "<message>"` et `git push` !***

Un playbook pour installer Apache
---------------------------------

1.  Créons un autre playbook pour installer et configurer Apache. Copiez
    **ping.yml**, et renommez-le en **apache.yml**.
2.  Supprimez la ligne **gather_facts** (attention de garder les
    alignements), puis remplacez les deux tâches précédentes par une
    tâche nommée « installer Apache » avec le module **apt**.
    Cherchez sur Internet comment utiliser ce module en cherchant
    « ansible apt module » (indice : cherchez les exemples sur la page
    **apt** de la documentation officielle d'Ansible sur ansible.com). **Attention : quel est le nom exact du paquet Apache à installer ? Ce n'est *pas* `apache` !**
3.  Lancez : `ansible-playbook apache.yml`
    - `changed : [node1]` et `changed : [node2]` devraient apparaître en jaune. Relancez la même commande. Cette fois-ci vous devriez obtenir des **ok** verts à la place.
4.  À l'aide de la documentation apt, modifiez légèrement (changez un
    mot) le playbook apache.yml pour désinstaller Apache.
5.  Trouvez, en relisant la documentation, comment modifier le
    playbook précédent pour effectuer un **update** du cache de apt
    (sans utiliser la commande bash `apt update`) (indice : cherchez
    dans les exemples la bonne option à utiliser pour le module apt).
    Testez en relançant le playbook.
6.  Réinstallez Apache (**present**) puis ajoutez une nouvelle tâche
    **systemd**, pour vous assurer que le service apache2 est bien
    démarré (**started**) (cf. documentation :p).
7.  Testez dans un navigateur que vos deux nœuds sont fonctionnels (ils
    devraient afficher la page d'exemple d'Apache) (vous connaissez leurs IP !)
8.  Poussez vos nouvelles modifications dans votre projet Gitlab.
 <!-- et mergez la branche à l'aide d'une merge request. -->

<!-- Cours sur l'idempotence et les variables dans Ansible.
------------------------------------------------------ -->

Configurer Apache pour personnaliser la page
---------------------------------------------

<!-- 1.  Pour cette section créez une branche **config_apache** dans `git`. -->
1.  Pour modifier la page d'exemple, nous allons éditer à l'aide d'Ansible la page index.html affichée par défaut par Apache. Pour cela utilisons le module template. Sa syntaxe fonctionne comme suit :

    ```yaml
    - name: personnaliser la page d'accueil d'Apache
      template:
      src: <template>
      dest: <chemin_vers_index>
      ```

3.  Téléchargez le fichier html d'exemple que vous montrait Apache à la fin de l'étape précédente grâce à votre navigateur (Fichier > Enregistrer sous). Editez son contenu, par exemple en modifiant le titre de la page (la balise `<title>` définit ce qui s'affiche dans le haut de la fenêtre, et la balise `<h1>` délimite le titre le plus important du corps de la page), puis renommez-le en `index.html.j2`. Cela va nous permettre d'utiliser Jinja2, le moteur de template qui nous permet d'utiliser des variables avec Ansible. Où est situé le fichier index qui nous intéresse sur les nœuds 1 et 2 ? (cherchez sur Internet le chemin du fichier index utilisé par défaut par Apache 2 dans Ubuntu)
   <!-- « default path index apache2 ubuntu » -->
4.  Ajoutez la tâche **template** entre **apt** et **systemd** pour écraser le fichier `index.html` sur les nodes par le fichier appelé `index.html.j2`.
5.  Quelle option utiliser pour que ce fichier créé appartienne à l'utilisateur **www-data**, plutôt qu'à root ? (documentation du module template)
6.  Les **handlers** sont des tâches à exécuter toujours à la fin du playbook si et seulement si elles ont été appelées par des tâches normales. Elle servent généralement à effectuer des post-traitements différés comme le redémarrage d'un service après modification de la configuration. Ajoutons un **handler** pour recharger le service apache à chaque modification de notre template. Premièrement, ajoutez `notify : reload apache` à la fin de la tâche template et aligné avec le mot template (deux espaces plus à gauche que `dest`). Deuxièmement, ajoutez à la fin du fichier (aligné avec **tasks**) :
    ```yaml
    handlers:
    - name: reload apache
      systemd:
      name: apache2
      state: reloaded
    ```

7.  Maintenant nous allons modifier le titre de la page en fonction du nœud. Dans le fichier template **index.html.j2**, ajoutez à la fin des titres (la balise `<title>` et la balise `<h1>`) le texte ` - Page servie depuis le nœud numéro {{ node_number }}`. La variable entre accolade agit comme une sorte de **« trou »** dans le template qui sera remplacé automatiquement par le moteur de template Jinja2 et Ansible par la valeur de la variable **node_number** (accolades comprises). Si la variable n'existe pas, comme pour l'instant, une erreur sera renvoyée au moment de l'exécution du module template.
9.  Lancez le playbook pour constater l'erreur `node_number is undefined`.
10. Ajoutons une section `vars: ` pour définir les variables du
    playbook. Au dessus de **tasks** ajoutez les deux lignes (**vars**
    doit être aligné avec **tasks**) :
    ```yaml
    vars:
    - node_number: 1
    ```

11. Relancez le playbook. Le « trou » a été complété par 1. Cependant
    nous aimerions définir une variable différente pour chaque nœud. Les
    variables spécifiques à une machine doivent être définies dans
    l'inventaire.

    -   Supprimez les deux lignes précédentes
    -   Dans `hosts.ini`, ajoutez `node_number=<number>` (remplacez par 1 et 2 !) juste après `ansible_host=<ip>` sur les deux lignes **node1** et **node2**.
    -   Relancez le playbook
    -   Si tout est OK, vérifiez que le numéro est modifié dans le
    navigateur (Maj+Ctrl+R dans Firefox pour actualiser la page en supprimant le cache !)

<!-- 12.  Nous allons maintenant ajouter 2 nœuds pour constater le potentiel
    pratique d'Ansible.

-   Importez deux nouvelles VM Ubuntu Server (EN COCHANT **Réinitialiser
    l'adresse MAC**) et configurez les réseaux (NatNetwork !)
-   Connectez-vous pour chercher les IP
-   Ajouter deux nouveaux nœuds dans l'inventaire (hosts.cfg) avec les
    bonnes IP et numéros.
-   En relançant le playbook vous devriez maintenant avoir quatre nœuds
    pour chaque étape !
-   Affichez dans le navigateur les pages n°3 et 4. -->
-   Enfin, poussez vos nouvelles modifications dans votre projet Gitlab.


Bilan Ansible :
---------------

-   Ansible peut être rejoué plusieurs fois (il est idempotent)
-   Ansible garantit l'état de certains éléments du système lorsqu'on le (re)joue
-   Ansible est (dès qu'on est un peu habitué·e) plus limpide que du bash

<!-- Bilan (ansible et les clusters statiques)
------------------------------------------ -->
