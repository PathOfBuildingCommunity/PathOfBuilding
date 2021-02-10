import hashlib
import logging
import pathlib
from typing import Optional
import xml.etree.ElementTree

"""This script requires at least Python 3.7.0 to run."""

logger = logging.getLogger(__name__)
logger.addHandler(logging.NullHandler())


def update_manifest(version: Optional[str] = None, replace: bool = False):
    """Update SHA1 hashes and version number for Path of Building's manifest file.

    :param version: Three-part version number following https://semver.org/.
    :param replace: Whether to overwrite the existing manifest file.
    :return:
    """
    supported_extensions = {".dll", ".jpg", ".lua", ".md", ".png", ".txt"}
    try:
        manifest = xml.etree.ElementTree.parse("manifest.xml")
    except FileNotFoundError:
        logger.critical(f"Manifest file not found in path '{pathlib.Path().cwd()}'")
        return
    root = manifest.getroot()

    for file in root.iter("File"):
        path = pathlib.Path(file.get("name"))
        if path.suffix not in supported_extensions:
            logger.debug(f"Skipping file type {path.suffix}")
            continue
        try:
            data = path.read_bytes()
        except FileNotFoundError:
            logger.error(f"File not found, skipping {path}")
            continue
        sha1_hash = hashlib.sha1(data).hexdigest()
        file.set("sha1", sha1_hash)
        logger.info(f"Path: {path} hash: {sha1_hash}")
    if version:
        root.find("Version").set("number", version)
        logger.info(f"Updated to version {version}")

    file_name = "manifest.xml" if replace else "manifest-updated.xml"
    manifest.write(file_name, encoding="UTF-8", xml_declaration=True)


def cli():
    """CLI for conveniently updating Path of Building's manifest file."""
    import argparse

    parser = argparse.ArgumentParser(
        usage="%(prog)s [options] filename",
        description="Update Path of Building's manifest file for a new release.",
        allow_abbrev=False,
    )
    parser.version = "1.0.0"
    parser.add_argument("--version", action="version")
    logging_level = parser.add_mutually_exclusive_group()
    logging_level.add_argument(
        "-v", "--verbose", action="store_true", help="Print more logging information"
    )
    logging_level.add_argument(
        "-q", "--quiet", action="store_true", help="Print no logging information"
    )
    parser.add_argument("--in-place", action="store_true", help="Replace original file")
    parser.add_argument(
        "--set-version",
        action="store",
        help="Set manifest version number",
        metavar="SEMVER",
    )
    args = parser.parse_args()

    logger.addHandler(logging.StreamHandler())
    if args.verbose:
        logger.setLevel(logging.INFO)
    elif args.quiet:
        logger.setLevel(logging.CRITICAL + 1)
    update_manifest(args.set_version or None, args.in_place)


if __name__ == "__main__":
    cli()
