import collections
import json

NODE_GROUPS = {
    "Juggernaut": [{"x": -8500, "y": 5200}, {"x": -8500, "y": 5200}],
    "Berserker": [{"x": -8500, "y": 3700}],
    "Chieftain": [{"x": -8680, "y": 2540}, {"x": -8500, "y": 2200}],
    "Raider": [{"x": 8800, "y": 5200}],
    "Deadeye": [{"x": 8800, "y": 2200}],
    "Pathfinder": [{"x": 8800, "y": 3700}],
    "Occultist": [{"x": -1500, "y": -7750}],
    "Elementalist": [{"x": 0, "y": -7750}],
    "Necromancer": [
        {"x": 1150, "y": -7400},
        {"x": 1315.439, "y": -7756.3},
        {"x": 1500, "y": -7750},
    ],
    "Slayer": [{"x": 1500, "y": 7700}],
    "Gladiator": [{"x": -1500, "y": 7700}],
    "Champion": [{"x": 0, "y": 7700}],
    "Inquisitor": [
        {"x": -8500, "y": -2200},
        {"x": -8224.14, "y": -2353.4},
        {"x": -8223.95, "y": -2046.16},
    ],
    "Hierophant": [{"x": -8500, "y": -3700}],
    "Guardian": [{"x": -8500, "y": -5200}],
    "Assassin": [{"x": 8800, "y": -5200}],
    "Trickster": [{"x": 8800, "y": -3700}],
    "Saboteur": [{"x": 8800, "y": -2200}],
    "Ascendant": [
        {"x": -7723.75, "y": 7168.07},
        {"x": -7632.92, "y": 7091.56},
        {"x": -7583.77, "y": 6561.85},
        {"x": -7539.11, "y": 7166.55},
        {"x": -7493.61, "y": 7195.65},
        {"x": -7492.04, "y": 6776.73},
        {"x": -7491.48, "y": 6720.17},
        {"x": -7403.21, "y": 6561.35},
        {"x": -7360.51, "y": 7434.15},
        {"x": -7268.5, "y": 7514.06},
        {"x": -7176, "y": 7432.69},
        {"x": -7129.21, "y": 6984.27},
        {"x": -7128.71, "y": 7406.9},
        {"x": -7128.15, "y": 6565.29},
        {"x": -7083.46, "y": 6528.57},
        {"x": -6988.94, "y": 6378.4},
        {"x": -6896.71, "y": 6538},
        {"x": -6852.15, "y": 7410.55},
        {"x": -6763.11, "y": 6774.71},
        {"x": -6763.06, "y": 7250.21},
        {"x": -6762.48, "y": 7195.67},
        {"x": -6741.4, "y": 7370.36},
        {"x": -6714.29, "y": 6799.46},
        {"x": -6622.5, "y": 6962.75},
        {"x": -6531.98, "y": 6800.78},
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
