"""Capture les réponses réelles de l'API YAY360 utilisées par l'application mobile (tests de contrat).

Usage (Git Bash, depuis yay360-mobile, plateforme Docker locale lancée) :
    PYTHONIOENCODING=utf-8 python -I tool/capturer_contrats.py ../yay360-backend/.env http://localhost:8080

Le mot de passe de démonstration est lu dans .env et n'est jamais affiché. Les jetons des réponses sont
remplacés par des valeurs factices avant l'écriture. Les données sont celles du jeu de démonstration (fictives).
Relancer ce script après toute modification d'un DTO de l'API, puis relancer flutter test.
"""
import json
import pathlib
import sys
import urllib.error
import urllib.request

fichier_env = pathlib.Path(sys.argv[1]).resolve(strict=True)
if fichier_env.name != '.env':
    sys.exit("Refus : le premier argument doit être le chemin d'un fichier .env.")
env = dict(l.split('=', 1) for l in fichier_env.read_text(encoding='utf-8').splitlines()
           if '=' in l and not l.lstrip().startswith('#'))
MDP = env['YAY360_DEMO_PASSWORD'].strip()
BASE = sys.argv[2].rstrip('/')
if not any(h in BASE for h in ('://localhost', '://127.0.0.1')):
    sys.exit("Refus : capture réservée à la plateforme locale (données de démonstration).")
SORTIE = pathlib.Path(__file__).resolve().parent.parent / 'test' / 'contrats'
JETONS = {'token', 'jetonRafraichissement', 'jetonPin'}


def appel(methode, chemin, jeton=None, corps=None):
    req = urllib.request.Request(BASE + chemin, method=methode,
                                 data=json.dumps(corps).encode() if corps is not None else None)
    req.add_header('Content-Type', 'application/json')
    if jeton:
        req.add_header('Authorization', 'Bearer ' + jeton)
    with urllib.request.urlopen(req, timeout=20) as r:
        return json.loads(r.read())


def masquer(valeur):
    if isinstance(valeur, dict):
        return {k: (f'{k}-factice' if k in JETONS and v else masquer(v)) for k, v in valeur.items()}
    if isinstance(valeur, list):
        return [masquer(v) for v in valeur]
    return valeur


def ecrire(nom, contenu):
    SORTIE.mkdir(parents=True, exist_ok=True)
    (SORTIE / f'{nom}.json').write_text(json.dumps(masquer(contenu), ensure_ascii=False, indent=2) + '\n',
                                        encoding='utf-8')
    print(f'OK  | {nom}.json')


connexion = appel('POST', '/auth/login', corps={'email': 'awa.ndiaye.demo@yay360.sn', 'password': MDP})
jeton = connexion['token']
ecrire('connexion', connexion)
ecrire('demarrer_numero_inconnu', appel('POST', '/auth/mobile/demarrer', corps={'telephone': '+221709999999'}))
ecrire('ma_grossesse', appel('GET', '/grossesses/ma-grossesse', jeton))
ecrire('mon_suivi', appel('GET', '/grossesses/mon-suivi', jeton))
ecrire('mon_plan_cpn', appel('GET', '/grossesses/mon-plan-cpn', jeton))
ecrire('mes_rendez_vous', appel('GET', '/rendez-vous/mes-rendez-vous', jeton))
alertes = appel('GET', '/alertes/mes-alertes', jeton)
if not alertes:
    sys.exit("ÉCHEC | aucune alerte de démonstration pour la patiente : capture de l'alerte impossible.")
ecrire('alerte', alertes[0])
