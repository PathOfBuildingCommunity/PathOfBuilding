from __future__ import annotations

import dataclasses
import json
import logging
import os
import pathlib
import random

logging.basicConfig(level=logging.INFO)


@dataclasses.dataclass(frozen=True) #, slots=True) #, slots breaks becouse its already defined?
class Point2D:
    """Two-dimensional point. Supports subtracting points."""
    x: int
    y: int

    def __sub__(self, other: Point2D) -> Point2D:
        return Point2D(self.x - other.x, self.y - other.y)


NODE_GROUPS = {
    "Juggernaut": Point2D(-10400, 5200),
    "Berserker": Point2D(-10400, 3700),
    "Chieftain": Point2D(-10400, 2200),
    "Raider": Point2D(10200, 5200),
    "Deadeye": Point2D(10200, 2200),
    "Pathfinder": Point2D(10200, 3700),
    "Occultist": Point2D(-1500, -9850),
    "Elementalist": Point2D(0, -9850),
    "Necromancer": Point2D(1500, -9850),
    "Slayer": Point2D(1500, 9800),
    "Gladiator": Point2D(-1500, 9800),
    "Champion": Point2D(0, 9800),
    "Inquisitor": Point2D(-10400, -2200),
    "Hierophant": Point2D(-10400, -3700),
    "Guardian": Point2D(-10400, -5200),
    "Assassin": Point2D(10200, -5200),
    "Trickster": Point2D(10200, -3700),
    "Saboteur": Point2D(10200, -2200),
    "Ascendant": Point2D(-7800, 7200),
}
EXTRA_NODES = {
	"Elementalist": [{"Node": {"name": "Nine Lives", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Int.png", "isNotable": True, 
		"stats": ["25% of Damage taken Recouped as Life, Mana and Energy Shield", "Recoup Effects instead occur over 3 seconds"], "reminderText": ["(Only Damage from Hits can be Recouped, over 4 seconds following the Hit)"]}, 
		"offset": Point2D(0, -1000)}],
	"Hierophant": [{"Node": {"name": "Searing Purity", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/StrInt.png", "isNotable": True, 
		"stats": ["45% of Chaos Damage taken as Fire Damage", "45% of Chaos Damage taken as Lightning Damage"], "reminderText": []}, 
		"offset": Point2D(-1000, 0)}],
	"Berserker": [{"Node": {"name": "MNode", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Str.png", "isNotable": True, "stats": [], "reminderText": []}, 
		"offset": Point2D(-1000, 0)}],
	"Ascendant": [{"Node": {"name": "ANode", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/SkillPoint.png", "stats": [], "reminderText": []}, 
		"offset": Point2D(-1000, 1000)}],
	"Champion": [{"Node": {"name": "DNode", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/StrDex.png", "isNotable": True, "stats": [], "reminderText": []}, 
		"offset": Point2D(0, 1000)}],
	"Pathfinder": [{"Node": {"name": "RNode", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Dex.png", "isNotable": True, "stats": [], "reminderText": []}, 
		"offset": Point2D(1000, 0)}],
	"Trickster": [{"Node": {"name": "SNode", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/DexInt.png", "isNotable": True, "stats": [], "reminderText": []}, 
		"offset": Point2D(1000, 0)}],
}


def fix_ascendancy_positions(path: os.PathLike) -> None:
    """Normalise the relative positions of ascendancy nodes on the passive skill tree.

    Ascendancy positions in the passive skill tree data we receive from GGG look
    scrambled, which is why we have to fix them before importing the skill tree in PoB.

    .. warning:: Overwrites the input file in-place.

    :param path: File path to a JSON passive skill tree data file.
    :return:
    """
    with open(path, "rb") as f:
        data = json.load(f)
    ascendancy_groups = [
        (data["nodes"][group["nodes"][0]]["ascendancyName"], group)
        for group in data["groups"].values()
        if "ascendancyName" in data["nodes"][group["nodes"][0]]
    ]
    ascendancy_starting_point = {
        ascendancy: Point2D(group["x"], group["y"])
        for ascendancy, group in ascendancy_groups
        for node in group["nodes"]
        if "isAscendancyStart" in data["nodes"][node]
    }
    for ascendancy, group in ascendancy_groups:
        offset = NODE_GROUPS[ascendancy] - ascendancy_starting_point[ascendancy]
        group["x"] += offset.x
        group["y"] += offset.y
    for ascendancy in EXTRA_NODES:
        for node in EXTRA_NODES[ascendancy]:
            node["Node"]["skill"] = random.randint(0, 65535)
            while str(node["Node"]["skill"]) in data["nodes"]:
                node["Node"]["skill"] = random.randint(0, 65535)
            newGroup = random.randint(0, 65535)
            while str(newGroup) in data["groups"]:
                newGroup = random.randint(0, 65535)
            data["groups"][newGroup] = {"x": NODE_GROUPS[ascendancy].x + node["offset"].x, "y": NODE_GROUPS[ascendancy].y + node["offset"].y, "orbits": [0], "nodes": [node["Node"]["skill"]]}
            node["Node"]["ascendancyName"] = ascendancy
            node["Node"]["group"] = newGroup
            node["Node"]["orbit"] = 0
            node["Node"]["orbitIndex"] = 0
            node["Node"]["out"] = []
            node["Node"]["in"] = []
            data["nodes"][node["Node"]["skill"]] = node["Node"]
    with open(path, "w", encoding="utf-8") as o:
        json.dump(data, o, indent=4)


def main(root: pathlib.Path) -> None:
    """Fix all passive skill tree JSONs found in root directory.

    .. warning: Overwrites all matched files in-place.

    :param root: File path to root directory.
    :return:
    """
    for file in root.glob("**/data.json"):
        fix_ascendancy_positions(file)
        logging.info(f"Found and processed file '{file}'.")


if __name__ == "__main__":
    main(pathlib.Path("src/TreeData"))
