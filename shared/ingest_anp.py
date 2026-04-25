"""
Ingestão dos CSVs públicos da ANP (Levantamento Semanal de Preços de Combustíveis).

Baixa um arquivo CSV da URL informada, salva localmente em layout
particionado (raw/anp/year=YYYY/month=MM/<filename>) e, opcionalmente,
faz upload para S3, Azure Blob ou GCS.

Os CSVs da ANP são publicados em:
    https://www.gov.br/anp/pt-br/centrais-de-conteudo/dados-abertos/serie-historica-de-precos-de-combustiveis

Uso:
    python ingest_anp.py --url <URL_CSV> --target local
    python ingest_anp.py --url <URL_CSV> --target aws
    python ingest_anp.py --url <URL_CSV> --target azure
    python ingest_anp.py --url <URL_CSV> --target gcp

Auth: usa as credenciais default de cada cloud (perfil AWS, az login, gcloud ADC).
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse

import requests
import yaml


HERE = Path(__file__).resolve().parent
DEFAULT_CONFIG = HERE / "config.yaml"
DEFAULT_LOCAL_OUT = HERE.parent / "data"


@dataclass
class IngestResult:
    local_path: Path
    remote_uri: str | None
    bytes_written: int


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--url", required=True, help="URL pública do CSV da ANP")
    p.add_argument(
        "--target",
        choices=["local", "aws", "azure", "gcp"],
        default="local",
        help="Onde gravar o arquivo após o download",
    )
    p.add_argument("--config", type=Path, default=DEFAULT_CONFIG, help="Caminho do config.yaml")
    p.add_argument("--out", type=Path, default=DEFAULT_LOCAL_OUT, help="Diretório local base")
    p.add_argument("--reference-date", help="Data de referência YYYY-MM-DD (default: hoje UTC)")
    return p.parse_args()


def load_config(path: Path) -> dict:
    if not path.exists():
        sys.exit(f"config não encontrado: {path}. Copie config.example.yaml para config.yaml.")
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def filename_from_url(url: str) -> str:
    name = Path(urlparse(url).path).name or "anp.csv"
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name)


def partition_key(reference_date: str | None) -> tuple[int, int]:
    if reference_date:
        d = datetime.strptime(reference_date, "%Y-%m-%d")
    else:
        d = datetime.now(timezone.utc)
    return d.year, d.month


def download(url: str, dest: Path) -> int:
    dest.parent.mkdir(parents=True, exist_ok=True)
    total = 0
    with requests.get(url, stream=True, timeout=60) as r:
        r.raise_for_status()
        with dest.open("wb") as f:
            for chunk in r.iter_content(chunk_size=1 << 15):
                if chunk:
                    f.write(chunk)
                    total += len(chunk)
    return total


def upload_aws(local: Path, key: str, cfg: dict) -> str:
    import boto3

    session = boto3.Session(profile_name=cfg.get("profile"), region_name=cfg["region"])
    s3 = session.client("s3")
    s3.upload_file(str(local), cfg["bucket"], key)
    return f"s3://{cfg['bucket']}/{key}"


def upload_azure(local: Path, key: str, cfg: dict) -> str:
    from azure.identity import DefaultAzureCredential
    from azure.storage.blob import BlobServiceClient

    account_url = f"https://{cfg['storage_account']}.blob.core.windows.net"
    service = BlobServiceClient(account_url=account_url, credential=DefaultAzureCredential())
    blob = service.get_blob_client(container=cfg["container"], blob=key)
    with local.open("rb") as f:
        blob.upload_blob(f, overwrite=True)
    return f"{account_url}/{cfg['container']}/{key}"


def upload_gcp(local: Path, key: str, cfg: dict) -> str:
    from google.cloud import storage

    client = storage.Client(project=cfg["project"])
    bucket = client.bucket(cfg["bucket"])
    blob = bucket.blob(key)
    blob.upload_from_filename(str(local))
    return f"gs://{cfg['bucket']}/{key}"


UPLOADERS = {"aws": upload_aws, "azure": upload_azure, "gcp": upload_gcp}


def run(args: argparse.Namespace) -> IngestResult:
    year, month = partition_key(args.reference_date)
    fname = filename_from_url(args.url)

    local_path = args.out / "raw" / "anp" / f"year={year}" / f"month={month:02d}" / fname
    print(f"[1/3] download → {local_path}")
    written = download(args.url, local_path)
    print(f"      {written:,} bytes")

    remote_uri: str | None = None
    if args.target != "local":
        cfg = load_config(args.config)
        prefix = cfg.get("storage_prefix", "raw/anp").rstrip("/")
        key = f"{prefix}/year={year}/month={month:02d}/{fname}"
        target_cfg = cfg[args.target]
        print(f"[2/3] upload {args.target} → {key}")
        remote_uri = UPLOADERS[args.target](local_path, key, target_cfg)
        print(f"      {remote_uri}")
    else:
        print("[2/3] target=local, skip upload")

    print("[3/3] ok")
    return IngestResult(local_path=local_path, remote_uri=remote_uri, bytes_written=written)


if __name__ == "__main__":
    run(parse_args())
