TP1 :
### Récupérer les images pré-configurées

Pour avoir tous les mêmes images de base générons-les depuis un script pré-installé, dans un terminal lancez :
```bash
bash /opt/lxd.sh
``` 


### Imports et includes

Il est possible d'importer le contenu d'autres fichiers dans un playbook:

- `import_tasks`: importe une liste de tâches (atomiques)
- `import_playbook`: importe une liste de play contenus dans un playbook.

Les deux instructions précédentes désignent un import **statique** qui est résolu avant l'exécution.

Au contraire, `include_tasks` permet d'intégrer une liste de tâche **dynamiquement** pendant l'exécution.

Par exemple :

```yaml
vars:
  apps:
    - app1
    - app2
    - app3

tasks:
  - include_tasks: install_app.yml
    loop: "{{ apps }}"
```

Ce code indique à Ansible d'exécuter une série de tâches pour chaque application de la liste. On pourrait remplacer cette liste par une liste dynamique. Comme le nombre d'imports ne peut pas facilement être connu à l'avance on **doit** utiliser `include_tasks`.

Savoir si on doit utiliser `include` ou `import` se fait selon les cas et avec tâtonnement le plus souvent.
>>>>>>> 5c55087 (coquilles et modifs légères ansible)

---


## changed_when / failed_when / ignore_errors

## Les conditions

## Les tags


