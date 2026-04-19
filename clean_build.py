"""Clean build script - removes only the target's build/dist subdirectories.

Usage:
    python3 clean_build.py <target>   # e.g. WorkLog or WorkLogServer
    python3 clean_build.py            # legacy: removes entire build/ and dist/
"""
import shutil
import os
import sys
import time

def remove_dir(path):
    if not os.path.exists(path):
        print(f"  {path} does not exist, skipping")
        return True

    for attempt in range(3):
        try:
            print(f"  Removing {path}... (attempt {attempt + 1}/3)")
            shutil.rmtree(path, ignore_errors=True)

            if os.path.exists(path):
                import stat
                def handle_remove_readonly(func, path, exc):
                    os.chmod(path, stat.S_IWRITE)
                    func(path)
                shutil.rmtree(path, onerror=handle_remove_readonly)

            if not os.path.exists(path):
                print(f"  [OK] {path} removed successfully")
                return True

            time.sleep(0.5)
        except Exception as e:
            print(f"  Warning: {e}")
            if attempt < 2:
                time.sleep(1)

    print(f"  [WARNING] Could not fully remove {path}")
    return False

target = sys.argv[1] if len(sys.argv) > 1 else None

print("Cleaning build directories...")
print()

success = True
if target:
    # Only remove this target's subdirectories, leaving other builds intact
    success &= remove_dir(os.path.join("build", target))
    success &= remove_dir(os.path.join("dist", target))
else:
    success &= remove_dir("build")
    success &= remove_dir("dist")

print()
if success:
    print("[SUCCESS] Clean completed successfully!")
else:
    print("[WARNING] Clean completed with warnings")
