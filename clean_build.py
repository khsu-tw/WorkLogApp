"""Clean build script - removes build and dist directories"""
import shutil
import os
import time

def remove_dir(path):
    """Remove directory with retries"""
    if not os.path.exists(path):
        print(f"  {path} does not exist, skipping")
        return True

    for attempt in range(3):
        try:
            print(f"  Removing {path}... (attempt {attempt + 1}/3)")
            shutil.rmtree(path, ignore_errors=True)

            # Force remove if still exists
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

print("Cleaning build directories...")
print()

success = True
success &= remove_dir("build")
success &= remove_dir("dist")

print()
if success:
    print("[SUCCESS] Clean completed successfully!")
else:
    print("[WARNING] Clean completed with warnings")
