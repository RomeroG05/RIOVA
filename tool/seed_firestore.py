#!/usr/bin/env python3
"""Sube el contenido de RÍOVA (firebase/seed.json) a Cloud Firestore.

Uso (desde la raíz del proyecto):

    flutter test tool/export_content_test.dart   # genera firebase/seed.json
    python3 tool/seed_firestore.py               # lo sube a Firestore
    python3 tool/seed_firestore.py --prune       # y borra documentos viejos
                                                 # de games/medals/missions/quizBank

Las reglas de producción (firestore.rules) no permiten que la app escriba
contenido. Para volver a subirlo con esas reglas activas, pasa un token de
una cuenta con acceso al proyecto:

    FIRESTORE_TOKEN="$(gcloud auth print-access-token)" python3 tool/seed_firestore.py

Sobrescribe los documentos con el mismo id (las ediciones hechas en la
consola sobre esos documentos se pierden). No toca `users`, `sectorStats`
ni `gameStats`.
"""
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def to_value(v):
    if v is None:
        return {"nullValue": None}
    if isinstance(v, bool):
        return {"booleanValue": v}
    if isinstance(v, int):
        return {"integerValue": str(v)}
    if isinstance(v, float):
        return {"doubleValue": v}
    if isinstance(v, str):
        return {"stringValue": v}
    if isinstance(v, list):
        return {"arrayValue": {"values": [to_value(x) for x in v]}}
    if isinstance(v, dict):
        return {"mapValue": {"fields": {k: to_value(x) for k, x in v.items()}}}
    raise TypeError(f"Tipo no soportado: {type(v)}")


PRUNABLE = ("games", "medals", "missions", "quizBank")


def prune_writes(base, seed, api_key):
    """Borra de las colecciones de catálogo los documentos que ya no existen."""
    out = []
    for col in PRUNABLE:
        url = f"https://firestore.googleapis.com/v1/{base}/{col}?pageSize=300&key={api_key}"
        with urllib.request.urlopen(url, timeout=60) as r:
            docs = json.load(r).get("documents", [])
        for d in docs:
            doc_id = d["name"].rsplit("/", 1)[-1]
            if doc_id not in seed.get(col, {}):
                print(f"Se borrará {col}/{doc_id}")
                out.append({"delete": d["name"]})
    return out


def main():
    services = json.load(open(os.path.join(ROOT, "android/app/google-services.json")))
    project = services["project_info"]["project_id"]
    api_key = services["client"][0]["api_key"][0]["current_key"]
    seed = json.load(open(os.path.join(ROOT, "firebase/seed.json")))

    base = f"projects/{project}/databases/(default)/documents"
    writes = []
    for collection, docs in seed.items():
        for doc_id, data in docs.items():
            writes.append({
                "update": {"name": f"{base}/{collection}/{doc_id}", "fields": {k: to_value(v) for k, v in data.items()}},
                "updateTransforms": [{"fieldPath": "updatedAt", "setToServerValue": "REQUEST_TIME"}],
            })

    if "--prune" in sys.argv:
        writes += prune_writes(base, seed, api_key)

    token = os.environ.get("FIRESTORE_TOKEN")
    url = f"https://firestore.googleapis.com/v1/{base}:commit"
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    else:
        url += f"?key={api_key}"

    for i in range(0, len(writes), 400):
        chunk = writes[i:i + 400]
        req = urllib.request.Request(url, data=json.dumps({"writes": chunk}).encode(), headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                json.load(r)
        except urllib.error.HTTPError as e:
            print("Error", e.code, e.read().decode()[:500])
            sys.exit(1)
        print(f"Subidos {i + len(chunk)}/{len(writes)} documentos")
    print("Listo:", ", ".join(f"{k} ({len(v)})" for k, v in seed.items()))


if __name__ == "__main__":
    main()
