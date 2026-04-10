---
name: user_story_writing
description: >
  Use this skill whenever the user wants to create, write, or generate user stories — whether they provide raw business requirements, functional specs, feature descriptions, or any other input describing what needs to be built. Always activate this skill when the user mentions "user story", "user stories", "histoire utilisateur", "functional requirement", "feature request", or when they paste a description of something that should be developed. This skill is particularly suited for functional analysts who receive business input and need to translate it into well-structured user stories using the Gherkin methodology. Input can be in Dutch, English, or French — output is ALWAYS in French.
---

# User Story Writing Skill

You are assisting a **functional analyst** who receives business requirements (from business analysts or stakeholders) and transforms them into well-defined user stories for developers. Your role is to act as an expert in formalizing these requirements using best practices.

## Core Rules

1. **Output language is ALWAYS French**, regardless of the input language (Dutch, English, or French).
2. Use the **Gherkin methodology** for acceptance criteria (Given / When / Then).
3. User stories follow the standard format: **"En tant que... je veux... afin de..."**

---

## User Story Structure

For each user story, produce the following sections in French:

```
## User Story: [Titre court et descriptif]

**Identifiant**: US-[numéro ou slug]
**Priorité**: [À définir / Haute / Moyenne / Basse]

---

### Description

En tant que **[type d'utilisateur]**,
je veux **[action ou fonctionnalité souhaitée]**,
afin de **[bénéfice ou valeur attendue]**.

---

### Critères d'acceptation (Gherkin)

**Scénario 1 : [Titre du scénario principal]**
```gherkin
Étant donné [contexte initial / état du système]
Quand [action effectuée par l'utilisateur ou l'événement déclencheur]
Alors [résultat attendu / comportement du système]
```

**Scénario 2 : [Cas alternatif ou cas d'erreur]**
```gherkin
Étant donné [contexte]
Quand [action]
Alors [résultat]
```

_(Ajouter autant de scénarios que nécessaire pour couvrir les cas métier importants)_

---

### Définition of Done (DoD)

- [ ] Les critères d'acceptation ci-dessus sont tous validés
- [ ] Les tests unitaires sont écrits et passent
- [ ] La fonctionnalité est revue et approuvée par l'analyste fonctionnel
- [ ] La documentation technique est mise à jour si nécessaire

---

### Dépendances

_(Autres user stories ou composants dont cette story dépend)_
```

---

## Gherkin Language Reference (French)

Always use the French Gherkin keywords:

| English       | French         |
|---------------|----------------|
| Given         | Étant donné    |
| When          | Quand          |
| Then          | Alors          |
| And           | Et             |
| But           | Mais           |
| Scenario      | Scénario       |
| Feature       | Fonctionnalité |
| Background    | Contexte       |

---

## How to Process Input

When you receive input from the functional analyst:

1. **Detect the input language** (Dutch, English, or French) — but always respond in French.
2. **Identify the stakeholders / user types** mentioned or implied.
3. **Extract the core need** — what is the user trying to accomplish?
4. **Identify the business value** — why does this matter?
5. **Define acceptance criteria** using Gherkin scenarios:
   - Always write a **happy path** scenario (the main flow).
   - Always write at least one **edge case or error scenario**.
   - Add additional scenarios if the requirement implies multiple business rules.
6. **Propose a short, meaningful title** for the story.
7. **Flag ambiguities** in the Notes section if the input is unclear, so the analyst can follow up with the business.

---

## Multiple Stories from One Input

If the input describes several distinct functionalities, **split them into separate user stories**. A good user story should be:
- **Small enough** to be completed in one sprint.
- **Independent** enough to be delivered without blocking others.
- **Testable** via the Gherkin acceptance criteria.

When splitting, number the stories and explain the rationale briefly.

---

## Example

**Input (Dutch):**
> "Als gebruiker wil ik kunnen inloggen met mijn e-mailadres en wachtwoord. Als ik mijn wachtwoord vergeten ben, moet ik het kunnen resetten via e-mail."

**Output (French):**

---

## User Story: Connexion par e-mail et mot de passe

**Identifiant**: US-001
**Priorité**: Haute

### Description

En tant qu'**utilisateur enregistré**,
je veux **me connecter à l'application avec mon adresse e-mail et mon mot de passe**,
afin d'**accéder à mon espace personnel de manière sécurisée**.

### Critères d'acceptation (Gherkin)

**Scénario 1 : Connexion réussie**
```gherkin
Étant donné que je suis sur la page de connexion
Et que je possède un compte actif
Quand je saisis mon adresse e-mail et mon mot de passe corrects
Et que je clique sur "Se connecter"
Alors je suis redirigé vers mon tableau de bord
Et un message de bienvenue s'affiche
```

**Scénario 2 : Identifiants incorrects**
```gherkin
Étant donné que je suis sur la page de connexion
Quand je saisis un e-mail ou un mot de passe incorrect
Et que je clique sur "Se connecter"
Alors un message d'erreur s'affiche : "E-mail ou mot de passe incorrect"
Et je reste sur la page de connexion
```

### Définition of Done (DoD)
- [ ] Les critères d'acceptation ci-dessus sont tous validés
- [ ] Les tests unitaires sont écrits et passent
- [ ] La fonctionnalité est revue et approuvée par l'analyste fonctionnel
- [ ] La documentation technique est mise à jour si nécessaire

### Dépendances
_(Aucune identifiée)_

---

## User Story: Réinitialisation du mot de passe par e-mail

**Identifiant**: US-002
**Priorité**: Haute

### Description

En tant qu'**utilisateur ayant oublié son mot de passe**,
je veux **recevoir un lien de réinitialisation par e-mail**,
afin de **retrouver l'accès à mon compte sans contacter le support**.

### Critères d'acceptation (Gherkin)

**Scénario 1 : Demande de réinitialisation réussie**
```gherkin
Étant donné que je suis sur la page de connexion
Quand je clique sur "Mot de passe oublié"
Et que je saisis mon adresse e-mail enregistrée
Alors je reçois un e-mail contenant un lien de réinitialisation valide pendant 24 heures
Et un message de confirmation s'affiche à l'écran
```

**Scénario 2 : E-mail non reconnu**
```gherkin
Étant donné que je suis sur la page "Mot de passe oublié"
Quand je saisis une adresse e-mail qui n'est pas dans le système
Alors un message s'affiche : "Si cet e-mail existe dans notre système, vous recevrez un lien de réinitialisation"
```

### Définition of Done (DoD)
- [ ] Les critères d'acceptation ci-dessus sont tous validés
- [ ] Les tests unitaires sont écrits et passent
- [ ] La fonctionnalité est revue et approuvée par l'analyste fonctionnel
- [ ] La documentation technique est mise à jour si nécessaire

### Dépendances
- US-001 (Connexion par e-mail et mot de passe)

---

## Tips for the Analyst

- If the business requirement is vague, write the user story with your best interpretation and flag the uncertainties in the **Dépendances** section or a comment.
- If a requirement touches both UI and back-end logic in a significant way, consider whether it should be split into a front-end story and a back-end story.
- When in doubt about the user type, be specific: prefer "utilisateur non connecté", "administrateur système", "gestionnaire de commandes" over generic terms like "utilisateur".
