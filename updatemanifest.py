import xml.etree.ElementTree
import hashlib

manifest = xml.etree.ElementTree.parse("manifest.xml")
root = manifest.getroot()

for file in root.iter("File"):
	path = file.get('name')	
	if path[-4:] != ".lua" and path[-4:] != ".txt":
		print("Skipping file type {}".format(path[-4:]))
		continue
	try:
		hash = hashlib.sha1(open(path, 'rb').read()).hexdigest()
		file.set("sha1", hash)
		print("path {} hash {}".format(path,hash))
	except FileNotFoundError:
		print("file not found, skipping: {}".format(path))
		continue
		
manifest.write("manifest-updated.xml")