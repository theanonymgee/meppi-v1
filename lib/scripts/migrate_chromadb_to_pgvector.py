#!/usr/bin/env python3
"""
ChromaDB to PostgreSQL Migration Script

Exports ChromaDB embeddings to CSV format for PostgreSQL import.
Usage: python3 migrate_chromadb_to_pgvector.py
"""

import csv
import sys
from pathlib import Path

try:
    import chromadb
    import numpy as np
except ImportError as e:
    print(f"Error: Missing required package: {e}")
    print("Install: pip3 install chromadb numpy")
    sys.exit(1)


# Configuration
CHROMADB_PATH = "/home/theanonymgee/.openclaw/workspace/dev/projects/gsm-rag/data/vectordb"
COLLECTION_NAME = "phones"
OUTPUT_CSV = "/tmp/phones_embeddings.csv"


def export_chromadb_to_csv(chromadb_path: str, output_csv: str, collection_name: str = "phones") -> dict:
    """
    Export ChromaDB embeddings to CSV file

    Args:
        chromadb_path: Path to ChromaDB persist directory
        output_csv: Output CSV file path
        collection_name: ChromaDB collection name

    Returns:
        dict with export statistics
    """
    print(f"=== ChromaDB to CSV Export ===")
    print(f"ChromaDB Path: {chromadb_path}")
    print(f"Collection: {collection_name}")
    print(f"Output CSV: {output_csv}")
    print()

    # Initialize ChromaDB client
    print("1. Connecting to ChromaDB...")
    client = chromadb.PersistentClient(path=chromadb_path)

    # Get collection
    print(f"2. Loading collection '{collection_name}'...")
    collection = client.get_collection(collection_name)

    # Get collection stats
    count = collection.count()
    print(f"   Total embeddings: {count}")

    if count == 0:
        print("   ERROR: No embeddings found in collection")
        return {"exported_count": 0, "errors": ["No embeddings found"]}

    # Fetch all data
    print("3. Fetching all embeddings...")
    results = collection.get(include=["embeddings", "metadatas", "documents"])

    embeddings = results["embeddings"]
    metadatas = results["metadatas"]
    documents = results["documents"]

    print(f"   Fetched {len(embeddings)} records")

    # Validate data
    print("4. Validating data...")
    errors = []

    # Check dimensions
    dimensions = [len(emb) for emb in embeddings]
    if len(set(dimensions)) > 1:
        errors.append(f"Inconsistent dimensions: {set(dimensions)}")
    else:
        print(f"   All embeddings have {dimensions[0]} dimensions")

    # Write CSV
    print(f"5. Writing to CSV: {output_csv}")
    exported_count = 0
    skipped_count = 0

    with open(output_csv, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)

        # Header
        writer.writerow(['phone_id', 'brand', 'model', 'embedding'])

        for i, (emb, meta, doc) in enumerate(zip(embeddings, metadatas, documents)):
            try:
                phone_id = meta.get('id', '')
                brand = meta.get('brand', '')
                model = meta.get('model', '')

                if not phone_id:
                    skipped_count += 1
                    errors.append(f"Row {i}: Missing phone_id")
                    continue

                # Convert numpy array to list
                embedding_list = emb.tolist() if hasattr(emb, 'tolist') else list(emb)

                # Convert to string format for PostgreSQL: "[0.1, -0.2, ...]"
                embedding_str = str(embedding_list)

                writer.writerow([phone_id, brand, model, embedding_str])
                exported_count += 1

                if (i + 1) % 500 == 0:
                    print(f"   Progress: {i + 1}/{count}")

            except Exception as e:
                skipped_count += 1
                errors.append(f"Row {i}: {str(e)}")

    print(f"   Exported: {exported_count}")
    print(f"   Skipped: {skipped_count}")

    if errors:
        print(f"   Errors: {len(errors)}")
        if len(errors) <= 5:
            for error in errors:
                print(f"     - {error}")
        else:
            for error in errors[:5]:
                print(f"     - {error}")
            print(f"     ... and {len(errors) - 5} more")

    return {
        "exported_count": exported_count,
        "skipped_count": skipped_count,
        "total_count": count,
        "errors": errors
    }


def main():
    """Main execution"""
    print()

    # Validate ChromaDB path
    chromadb_path = Path(CHROMADB_PATH)
    if not chromadb_path.exists():
        print(f"ERROR: ChromaDB path not found: {CHROMADB_PATH}")
        sys.exit(1)

    # Export
    try:
        stats = export_chromadb_to_csv(
            chromadb_path=str(chromadb_path),
            output_csv=OUTPUT_CSV,
            collection_name=COLLECTION_NAME
        )

        print()
        print("=== Export Complete ===")
        print(f"Exported: {stats['exported_count']}")
        print(f"Skipped: {stats['skipped_count']}")
        print(f"Total: {stats['total_count']}")
        print(f"Output: {OUTPUT_CSV}")

        if stats['errors']:
            print(f"Errors: {len(stats['errors'])}")

        if stats['exported_count'] > 0:
            print()
            print("Next step:")
            print(f"  cd /home/theanonymgee/.openclaw/workspace/dev/projects/meppi-rails")
            print(f"  rails embeddings:import_from_csv CSV_FILE={OUTPUT_CSV}")
            sys.exit(0)
        else:
            print()
            print("ERROR: No embeddings exported")
            sys.exit(1)

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
