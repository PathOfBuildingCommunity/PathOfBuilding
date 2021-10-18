import collections
import json

NODE_GROUPS = {
    "Juggernaut": [
        {"x": -9900, "y": 5200}, 
        {"x": -9900, "y": 5200}
    ],
    "Berserker": [{"x": -9900, "y": 3700}],
    "Chieftain": [
        {"x": -10080, "y": 2540}, 
        {"x": -9900, "y": 2200}
    ],
    "Raider": [{"x": 10200, "y": 5200}],
    "Deadeye": [{"x": 10200, "y": 2200}],
    "Pathfinder": [{"x": 10200, "y": 3700}],
    "Occultist": [{"x": -1500, "y": -9850}],
    "Elementalist": [{"x": 0, "y": -9850}],
    "Necromancer": [
        {"x": 1150, "y": -9500},
        {"x": 1315.439, "y": -9856.3},
        {"x": 1500, "y": -9850},
    ],
    "Slayer": [{"x": 1500, "y": 9800}],
    "Gladiator": [{"x": -1500, "y": 9800}],
    "Champion": [{"x": 0, "y": 9800}],
    "Inquisitor": [
        {"x": -9900, "y": -2200},
        {"x": -9624.14, "y": -2353.4},
        {"x": -9623.95, "y": -2046.16},
    ],
    "Hierophant": [{"x": -9900, "y": -3700}],
    "Guardian": [{"x": -9900, "y": -5200}],
    "Assassin": [{"x": 10200, "y": -5200}],
    "Trickster": [{"x": 10200, "y": -3700}],
    "Saboteur": [{"x": 10200, "y": -2200}],
    "Ascendant": [
        {"x": -8253.75, "y": 7698.07},
        {"x": -8162.92, "y": 7621.56},
        {"x": -8113.77, "y": 7091.85},
        {"x": -8069.11, "y": 7696.55},
        {"x": -8023.61, "y": 7725.65},
        {"x": -8022.04, "y": 7306.73},
        {"x": -8021.48, "y": 7250.17},
        {"x": -7933.21, "y": 7091.35},
        {"x": -7890.51, "y": 7964.15},
        {"x": -7798.5, "y": 8044.06},
        {"x": -7706, "y": 7962.69},
        {"x": -7659.21, "y": 7524.27},
        {"x": -7658.71, "y": 7936.9},
        {"x": -7658.15, "y": 7095.29},
        {"x": -7613.46, "y": 7058.57},
        {"x": -7518.94, "y": 6908.4},
        {"x": -7426.71, "y": 7068},
        {"x": -7382.15, "y": 7940.55},
        {"x": -7293.11, "y": 7304.71},
        {"x": -7293.06, "y": 7780.21},
        {"x": -7292.48, "y": 7725.67},
        {"x": -7271.4, "y": 7900.36},
        {"x": -7244.29, "y": 7329.46},
        {"x": -7152.5, "y": 7492.75},
        {"x": -7061.98, "y": 7330.78},
    ],
}

def main():
    with open("data.json") as f:
        data = json.loads(f.read())

    ascendancy_count = collections.defaultdict.fromkeys(NODE_GROUPS, 0)

    for group in data["groups"]:
        if (
            data["groups"][group]["nodes"]
            and "ascendancyName" in data["nodes"][data["groups"][group]["nodes"][0]]
        ):
            asc = data["nodes"][data["groups"][group]["nodes"][0]]["ascendancyName"]
            data["groups"][group]["x"] = NODE_GROUPS[asc][ascendancy_count[asc]]["x"]
            data["groups"][group]["y"] = NODE_GROUPS[asc][ascendancy_count[asc]]["y"]
            ascendancy_count[asc] += 1

    with open("data_fixed.json", "w") as o:
        o.write(json.dumps(data, indent=4))


if __name__ == "__main__":
    main()
