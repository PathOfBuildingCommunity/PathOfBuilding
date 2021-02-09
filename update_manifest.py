import hashlib
import pathlib
import xml.etree.ElementTree

"""This script requires at least Python 3.7.0 to run."""


def update_manifest():
    supported_extensions = {".dll", ".jpg", ".lua", ".md", ".png", ".txt"}
    try:
        manifest = xml.etree.ElementTree.parse("manifest.xml")
    except FileNotFoundError:
        print(f"Manifest file not found in path '{pathlib.Path().cwd()}'!")
        return
    root = manifest.getroot()

    for file in root.iter("File"):
        path = pathlib.Path(file.get("name"))
        if path.suffix not in supported_extensions:
            print(f"Skipping file type {path.suffix}")
            continue
        try:
            data = path.read_bytes()
        except FileNotFoundError:
            print(f"File not found, skipping {path}")
            continue
        sha1_hash = hashlib.sha1(data).hexdigest()
        file.set("sha1", sha1_hash)
        print(f"Path: {path} hash: {sha1_hash}")
    manifest.write("manifest-updated.xml", encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    update_manifest()
