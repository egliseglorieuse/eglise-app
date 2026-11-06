# Application de gestion d’église : mise en service

Ce dossier contient tout ce qu’il faut :

- `index.html` : l’application (un seul fichier)
- `schema.sql` : la base de données, les comptes et la sécurité
- `LISEZMOI.md` : ce guide

Compter environ 30 minutes. Tout peut se faire gratuitement, depuis un navigateur.

## Étape 1 : créer la base de données (Supabase)

1. Créez un compte sur https://supabase.com puis cliquez sur **New project**. Choisissez un nom, un mot de passe de base de données (notez-le) et la région la plus proche.
2. Une fois le projet prêt, ouvrez **SQL Editor** (menu de gauche), cliquez sur **New query**, collez tout le contenu de `schema.sql` et cliquez sur **Run**. Le message « Success » doit s’afficher.
3. Ouvrez **Project Settings > API** et copiez deux valeurs :
   - **Project URL** (de la forme `https://xxxx.supabase.co`)
   - la clé **anon / public**

## Étape 2 : connecter l’application

Ouvrez `index.html` avec un éditeur de texte (le Bloc-notes suffit). Tout en haut du script, repérez ce bloc et remplacez les valeurs :

```js
var CONFIG={SUPABASE_URL:"https://VOTRE-PROJET.supabase.co",SUPABASE_ANON_KEY:"VOTRE_CLE_ANON_PUBLIQUE",EGLISE_NOM:"Mon Église"};
```

Mettez l’adresse du projet, la clé anon et le nom de votre église. N’utilisez jamais la clé « service_role ».

## Étape 3 : créer les comptes et attribuer les rôles

1. Dans Supabase : **Authentication > Users > Add user > Create new user**. Saisissez l’email et un mot de passe, et cochez **Auto Confirm User**. Faites-le pour chaque personne qui utilisera l’application.
2. Attribuez les rôles dans **SQL Editor** (remplacez l’email) :

```sql
update public.profiles set role = 'admin' where email = 'pasteur@exemple.org';
```

Rôles possibles : `admin`, `pasteur`, `secretaire`, `tresorier`. Sans rôle, la personne peut se connecter mais n’accède à rien.

| Rôle | Membres, groupes, cultes, programmes | Finances |
|---|---|---|
| admin | lecture et modification | lecture et modification |
| pasteur | lecture et modification | lecture et modification |
| secrétaire | lecture et modification | aucun accès |
| trésorier | lecture seule | lecture et modification |

3. Recommandé : dans **Authentication > Sign In / Providers > Email**, désactivez **Allow new users to sign up**, pour que personne d’autre ne puisse créer de compte.

Mot de passe oublié : dans **Authentication > Users**, ouvrez le compte et choisissez d’envoyer un lien de réinitialisation, ou créez-en un nouveau.

## Étape 4 : mettre l’application en ligne

Le plus simple : **Netlify Drop**. Allez sur https://app.netlify.com/drop et glissez le dossier contenant `index.html`. Vous obtenez une adresse à partager avec votre équipe.

Autre option : **Vercel** (https://vercel.com), en créant un projet à partir de ce dossier, sans paramètre particulier à régler.

Testez ensuite : ouvrez l’adresse, connectez-vous, ajoutez un membre, rechargez la page. Il doit toujours être là.

## À savoir pour l’utilisation

- **Enregistrement automatique** : chaque modification est enregistrée en quelques secondes. L’état s’affiche en bas du menu (« enregistré »).
- **Modifications simultanées** : si deux personnes modifient la même rubrique en même temps, la seconde reçoit un message et les données sont rechargées. Chacun doit alors refaire sa dernière saisie.
- **Photos** : elles sont envoyées dans l’espace de stockage Supabase. Toute personne qui possède le lien d’une photo peut la voir, mais les liens ne sont pas devinables. N’y mettez pas d’images confidentielles. Retirer une photo d’une édition ne libère pas l’espace de stockage.
- **Sauvegarde** : l’administrateur a un bouton « Exporter une sauvegarde » sur l’accueil, qui télécharge toutes les données en un fichier. Faites-le régulièrement. Supabase peut aussi exporter les tables.
- **Gratuit, avec des limites** : l’offre gratuite de Supabase met un projet en pause après une semaine sans utilisation. Un usage régulier l’évite. Au-delà, un abonnement payant existe.
- **Données personnelles** : les noms, téléphones et dons sont des données sensibles. Donnez un compte uniquement aux personnes qui en ont besoin.

## Si la connexion ne marche pas

Lisez le message en rouge sous le champ du mot de passe :

- **« L’application n’est pas encore configurée »** : l’adresse ou la clé Supabase n’a pas été remplacée dans `index.html` (étape 2). Remplacez-les, enregistrez le fichier et remettez-le en ligne.
- **« Email ou mot de passe incorrect »** : vérifiez le compte dans Supabase, sous Authentication > Users. L’utilisateur doit exister et avoir été créé avec **Auto Confirm User** coché.
- **« Votre compte est créé mais n’a pas encore été activé »** : exécutez la commande de l’étape 3 pour attribuer le rôle `admin`.
- **« Erreur de base de données »** : le script `schema.sql` n’a pas été exécuté en entier. Relancez-le dans SQL Editor.
- **« Connexion impossible »** : vérifiez la connexion internet et que l’adresse du projet est exacte, sans espace ni barre oblique à la fin.

Après chaque modification de `index.html`, il faut le remettre en ligne sur Netlify ou Vercel, puis recharger la page (touche Ctrl + F5).
