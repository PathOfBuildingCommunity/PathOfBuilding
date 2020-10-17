import hashlib
import os
import xml.etree.ElementTree


def update_manifest():
    manifest = xml.etree.ElementTree.parse("manifest.xml")
    root = manifest.getroot()

    for file in root.iter("File"):
        path = file.get('name')
        extension = os.path.splitext(path)[1]
        if extension not in (".lua", ".md", ".txt", ".png", ".jpg"):
            print(f"Skipping file type {extension}")
            continue
        try:
            with open(path, 'rb') as f:
                data = f.read()
            sha1_hash = hashlib.sha1(data).hexdigest()
            file.set("sha1", sha1_hash)
            print(f"Path: {path} hash: {sha1_hash}")
        except FileNotFoundError:
            print(f"File not found, skipping {path}")

    manifest.write("manifest-updated.xml")


if __name__ == "__main__":
    update_manifest()
