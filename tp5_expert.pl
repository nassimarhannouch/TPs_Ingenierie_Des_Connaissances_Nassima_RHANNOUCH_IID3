% TP5 - Système expert médical simplifié
% Réalisé par : Nassima RHANNOUCH, IID3
% Module : Ingénierie des connaissances

% ------------------------
% Partie 1 : Faits pour tests statiques
% ------------------------
% symptome(Patient, Symptom)
symptome(p1, fievre).
symptome(p1, toux).
symptome(p1, fatigue).

symptome(p2, mal_gorge).
symptome(p2, fievre).

symptome(p3, eternuements).
symptome(p3, nez_qui_coule).

% ------------------------
% Règles maladies pour patients fictifs
% ------------------------
maladie_grippe(Patient) :-
    symptome(Patient, fievre),
    symptome(Patient, courbatures),
    symptome(Patient, fatigue).

maladie_angine(Patient) :-
    symptome(Patient, mal_gorge),
    symptome(Patient, fievre).

maladie_covid(Patient) :-
    symptome(Patient, fievre),
    symptome(Patient, toux),
    symptome(Patient, fatigue).

maladie_allergie(Patient) :-
    symptome(Patient, eternuements),
    symptome(Patient, nez_qui_coule),
    \+ symptome(Patient, fievre).  % pas de fièvre

% Diagnostic global
diagnostic(Patient, grippe) :- maladie_grippe(Patient).
diagnostic(Patient, angine) :- maladie_angine(Patient).
diagnostic(Patient, covid) :- maladie_covid(Patient).
diagnostic(Patient, allergie) :- maladie_allergie(Patient).

% ------------------------
% Partie 2 : Interaction avec l'utilisateur
% ------------------------
:- dynamic a_symptome/1.
:- dynamic reponse_symptome/2.

% poser_question(Symptome) : pose la question et mémorise la réponse
poser_question(Symptome) :-
    format("Avez-vous ~w ? (o/n) ", [Symptome]),
    read(R),
    ( R == o ->
        assertz(reponse_symptome(Symptome, oui)),
        assertz(a_symptome(Symptome))
    ; R == n ->
        assertz(reponse_symptome(Symptome, non))
    ; write('Réponse non reconnue. Répondez par o (oui) ou n (non).'), nl,
      poser_question(Symptome)
    ).

% Vérifie si le symptôme est présent ou poser la question
a_symptome(Symptome) :-
    reponse_symptome(Symptome, oui), !.
a_symptome(Symptome) :-
    reponse_symptome(Symptome, non), !, fail.
a_symptome(Symptome) :-
    poser_question(Symptome).

% Liste de tous les symptômes
symptomes([fievre, toux, mal_gorge, fatigue, courbatures, mal_tete, eternuements, nez_qui_coule]).

% Réécriture des règles de maladies pour interaction
maladie_grippe :-
    a_symptome(fievre),
    a_symptome(courbatures),
    a_symptome(fatigue).

maladie_angine :-
    a_symptome(mal_gorge),
    a_symptome(fievre).

maladie_covid :-
    a_symptome(fievre),
    a_symptome(toux),
    a_symptome(fatigue).

maladie_allergie :-
    a_symptome(eternuements),
    a_symptome(nez_qui_coule),
    \+ a_symptome(fievre).

% trouver_maladies(L) : retourne la liste des maladies compatibles
trouver_maladies(L) :-
    findall(grippe, (maladie_grippe -> true), G1),
    findall(angine, (maladie_angine -> true), G2),
    findall(covid, (maladie_covid -> true), G3),
    findall(allergie, (maladie_allergie -> true), G4),
    append([G1,G2,G3,G4], All),
    sort(All, L).

% afficher_resultats(L) : affichage lisible
afficher_resultats([]) :-
    write('Aucune maladie probable trouvée.'), nl.
afficher_resultats(L) :-
    write('Diagnostics possibles :'), nl,
    forall(member(M, L), (write('- '), write(M), nl)).

% ------------------------
% Partie 3 : Explication (Pourquoi ?)
% ------------------------
caracteristiques(grippe, [fievre, courbatures, fatigue]).
caracteristiques(angine, [mal_gorge, fievre]).
caracteristiques(covid, [fievre, toux, fatigue]).
caracteristiques(allergie, [eternuements, nez_qui_coule]).

symptomes_confirmes(Maladie, Confirmes) :-
    caracteristiques(Maladie, L),
    findall(S, (member(S,L), a_symptome(S)), Confirmes).

expliquer(Maladie) :-
    symptomes_confirmes(Maladie, C),
    format("Vous pourriez avoir la ~w car : ", [Maladie]),
    write(C), nl.

% ------------------------
% Point d'entrée : expert.
% ------------------------
expert :-
    retractall(reponse_symptome(_, _)),
    retractall(a_symptome(_)),
    symptomes(S),
    forall(member(Sym, S), ( (reponse_symptome(Sym, _)) -> true ; poser_question(Sym) )),
    trouver_maladies(L),
    afficher_resultats(L),
    forall(member(M, L), (expliquer(M), nl)).
