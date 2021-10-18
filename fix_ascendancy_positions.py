import json

NODE_GROUPS = {
	"Juggernaut": {"x": -10400, "y": 5200},
	"Berserker": {"x": -10400, "y": 3700},
	"Chieftain": {"x": -10400, "y": 2200},
	"Raider": {"x": 10200, "y": 5200},
	"Deadeye": {"x": 10200, "y": 2200},
	"Pathfinder": {"x": 10200, "y": 3700},
	"Occultist": {"x": -1500, "y": -9850},
	"Elementalist": {"x": 0, "y": -9850},
	"Necromancer": {"x": 1500, "y": -9850},
	"Slayer": {"x": 1500, "y": 9800},
	"Gladiator": {"x": -1500, "y": 9800},
	"Champion": {"x": 0, "y": 9800},
	"Inquisitor": {"x": -10400, "y": -2200},
	"Hierophant": {"x": -10400, "y": -3700},
	"Guardian": {"x": -10400, "y": -5200},
	"Assassin": {"x": 10200, "y": -5200},
	"Trickster": {"x": 10200, "y": -3700},
	"Saboteur": {"x": 10200, "y": -2200},
	"Ascendant": {"x": -7800, "y": 7200},
}
ascLocations = {}
GroupOffset = {}


def main():
	with open("data.json") as f:
		data = json.loads(f.read())
	for group in data["groups"]:
		if (
			data["groups"][group]["nodes"]
			and "ascendancyName" in data["nodes"][data["groups"][group]["nodes"][0]]
		):
			for node in data["groups"][group]["nodes"]:
				if "isAscendancyStart" in data["nodes"][node]:
					ascLocations[data["nodes"][data["groups"][group]["nodes"][0]]["ascendancyName"]] = {"x": data["groups"][group]["x"], "y" : data["groups"][group]["y"]}
					break
	for group in data["groups"]:
		if (
			data["groups"][group]["nodes"]
			and "ascendancyName" in data["nodes"][data["groups"][group]["nodes"][0]]
		):
			asc = data["nodes"][data["groups"][group]["nodes"][0]]["ascendancyName"]
			GroupOffset[group] = {"x": (ascLocations[asc]["x"] - data["groups"][group]["x"]), "y": (ascLocations[asc]["y"] - data["groups"][group]["y"])}
	for group in data["groups"]:
		if (
			data["groups"][group]["nodes"]
			and "ascendancyName" in data["nodes"][data["groups"][group]["nodes"][0]]
		):
			asc = data["nodes"][data["groups"][group]["nodes"][0]]["ascendancyName"]
			data["groups"][group]["x"] = NODE_GROUPS[asc]["x"] - GroupOffset[group]["x"]
			data["groups"][group]["y"] = NODE_GROUPS[asc]["y"] - GroupOffset[group]["y"]
	with open("data_fixed.json", "w") as o:
		o.write(json.dumps(data, indent=4))
if __name__ == "__main__":
	main()