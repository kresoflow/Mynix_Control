import os

def replace_currency(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".dart"):
                path = os.path.join(root, file)
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        content = f.read()
                    if "₽" in content:
                        content = content.replace("₽", "с")
                        with open(path, "w", encoding="utf-8") as f:
                            f.write(content)
                        print(f"Updated {path}")
                except Exception as e:
                    print(f"Error reading {path}: {e}")

if __name__ == "__main__":
    replace_currency(".")
