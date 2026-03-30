#!/usr/bin/env python3
"""
Supabase to PocketBase Data Migration Script
"""

import os
import json
from pathlib import Path

print("Work Log Journal - Data Migration")
print("Supabase to PocketBase")
print("="*50)

# Load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv()
except:
    pass

# Check Supabase config
supabase_url = os.environ.get("SUPABASE_URL", "")
supabase_key = os.environ.get("SUPABASE_KEY", "")

if not supabase_url or not supabase_key:
    print("[ERROR] Supabase credentials not found in .env")
    print("Set SUPABASE_URL and SUPABASE_KEY to continue")
    exit(1)

# Check PocketBase config
pocketbase_url = os.environ.get("POCKETBASE_URL", "http://127.0.0.1:8090")
print(f"\n[INFO] PocketBase URL: {pocketbase_url}")
print(f"[INFO] Supabase URL: {supabase_url[:40]}...")

# Step 1: Export from Supabase
print("\n[1/3] Exporting from Supabase...")
try:
    from supabase import create_client
    sb = create_client(supabase_url, supabase_key)
    data = sb.table("worklog").select("*").execute().data
    print(f"[OK] Exported {len(data)} records")

    # Save backup
    backup_file = f"supabase_export_{Path(__file__).parent.name}.json"
    with open(backup_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"[OK] Backup saved: {backup_file}")
except Exception as e:
    print(f"[ERROR] Export failed: {e}")
    exit(1)

# Step 2: Import to PocketBase
print("\n[2/3] Importing to PocketBase...")
try:
    from pocketbase import PocketBase
    pb = PocketBase(pocketbase_url)

    # Test connection
    try:
        pb.collection("worklog").get_list(1, 1)  # page, per_page
        print("[OK] PocketBase connection successful")
    except Exception as e:
        print(f"[ERROR] Cannot connect to PocketBase: {e}")
        print("\nPlease ensure:")
        print(f"1. PocketBase is running at {pocketbase_url}")
        print("2. 'worklog' collection is created")
        print("3. API Rules allow public access")
        exit(1)

    # Check existing records to avoid duplicates
    print("[INFO] Checking for existing records...")
    try:
        existing = pb.collection("worklog").get_full_list()
        existing_hashes = {getattr(r, 'record_hash', None) for r in existing if hasattr(r, 'record_hash')}
        print(f"[INFO] Found {len(existing)} existing records")
    except:
        existing_hashes = set()

    # Import records
    imported = 0
    skipped = 0
    duplicates = 0

    for i, record in enumerate(data, 1):
        # Check for duplicate by record_hash
        record_hash = record.get('record_hash', '')
        if record_hash and record_hash in existing_hashes:
            duplicates += 1
            print(f"  [SKIP] Record {i} already exists (hash: {record_hash[:8]}...)")
            continue

        # Remove Supabase-specific and auto-generated fields
        clean = {k: v for k, v in record.items()
                 if k not in ('id', 'created_at', 'collectionId', 'collectionName', 'expand')}

        # Ensure all values are properly formatted
        for key in clean:
            if clean[key] is None:
                clean[key] = ""
            # Keep worklogs as-is (contains base64 images)
            elif key == 'worklogs':
                continue
            # Convert other values to string
            elif not isinstance(clean[key], str):
                clean[key] = str(clean[key])

        try:
            result = pb.collection("worklog").create(clean)
            imported += 1
            # Show progress with image info
            has_imgs = 'IMG_B64:' in clean.get('worklogs', '')
            img_marker = ' (with images)' if has_imgs else ''
            print(f"  [{i}/{len(data)}] {clean.get('customer', 'N/A')}{img_marker} - OK")
        except Exception as e:
            skipped += 1
            error_msg = str(e)
            print(f"[WARN] Record {i} ({clean.get('customer', 'N/A')}) failed:")
            print(f"       Error: {error_msg[:150]}")
            if skipped == 1:
                print(f"       Fields: {list(clean.keys())}")
                print(f"       Worklogs length: {len(clean.get('worklogs', ''))} chars")

    print(f"\n[OK] Imported {imported}/{len(data)} records")
    if duplicates > 0:
        print(f"[INFO] Skipped {duplicates} duplicates")
    if skipped > 0:
        print(f"[WARN] Failed {skipped} records")
except Exception as e:
    print(f"[ERROR] Import failed: {e}")
    exit(1)

print("\n[3/3] Migration complete!")
print(f"\nNext steps:")
print(f"1. Update .env: POCKETBASE_URL={pocketbase_url}")
print(f"2. Start app: python app.py")
print(f"3. Test functionality")
