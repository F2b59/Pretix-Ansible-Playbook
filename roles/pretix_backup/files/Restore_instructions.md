# Restauration d'une instance Pretix

Comme indiqué dans la [documentation officielle](https://docs.pretix.eu/self-hosting/maintenance/), une sauvegarde de Pretix est composée :
- d'une sauvegarde de la base de données PostgreSQL `pretix.sql`,
- d'une copie du dossier `/var/pretix-data`.

La procédure ci-après présuppose :
- qu'une instance Pretix vierge a été installée à l'aide de ce [playbook](https://github.com/F2b59/Pretix-Ansible-Playbook) sur une machine accessible à l'adresse pretix.example.com (utilisé pour le chemin de stockage de la sauvegarde sur le serveur de sauvegarde),
- que le serveur de sauvegarde est accessible à l'adresse backup.pretix.example.com,
- que la clé SSH de l'utilisateur `root` sur l'instance Pretix a été ajoutée dans le fichier `authorized_keys` de l'utilisateur `backup` sur le serveur de sauvegardes.

Sauf indication contraire, les commandes sont à exécuter en tant que `root`.


## Récupération des fichiers

### Cas d'une sauvegarde automatique

Si la sauvegarde a été effectuée automatiquement, il faut la récupérer avec Duplicity après avoir ajouté la clé SSH de l'utilisateur `root` dans le fichier `authorized_keys` de l'utilisateur `backup` du serveur de sauvegardes.

*(Remplacer backup.pretix.example.com par l'adresse du serveur de sauvegardes et pretix.example.com par l'adresse de l'instance Pretix utlisée comme chemin de sauvegarde.)*

Note perso : 2a02842b4001701be2411fffebca44.f2b.ee

```
duplicity --no-encryption restore rsync://backup@backup.pretix.example.com//home/backup/pretix.example.com/postgresql /home/backup/restore
duplicity --no-encryption restore rsync://backup@backup.pretix.example.com//home/backup/pretix.example.com/pretix /home/backup/restore
```

### Cas d'une sauvegarde manuelle

Si la sauvegarde a été créée manuellement avec le script `pretix-backup-oneshot.sh`, placer l'archive dans le dossier `/tmp`, et l'extraire dans `/home/backup/restore`.

*(Remplacer YYYY-MM-DD-HHMMSS dans le nom de l'archive.)*

```
tar -xvf /tmp/pretix-backup-YYYY-MM-DD-HHMMSS.tar.xz --strip-components 1 -C /home/backup/restore
```


## Restauration des données

Après avoir arrêté le service `pretix`, remplacer le dossier `/var/pretix-data` par celui obtenu à l'étape précédente. L'ID 15371 correspond à l'utilisateur pretixuser à l'intérieur du conteneur.

```
systemctl stop pretix.service
mv /var/pretix-data/ /var/pretix-data.bak/
cp -r /home/backup/restore/pretix-data /var/
chown -R 15371:15371 /var/pretix-data
```
Accéder à la CLI PostgreSQL avec :

```
sudo -u postgres psql
```
Puis supprimer et recréer la base de données Pretix.
```sql
REVOKE CONNECT ON DATABASE pretix FROM PUBLIC;
SELECT pg_terminate_backend(pg_stat_activity.pid)
  FROM pg_stat_activity
  WHERE pg_stat_activity.datname = 'pretix' AND pid <> pg_backend_pid();
DROP DATABASE pretix;
CREATE DATABASE pretix
  WITH OWNER = pretix
  ENCODING = 'UTF8';
GRANT ALL PRIVILEGES ON DATABASE pretix TO pretix;
\q
```
Restaurer la base de données et démarrer le service.
```
sudo -u postgres psql -U postgres -d pretix < /home/backup/restore/pretix.sql
systemctl start pretix.service
```
