from __future__ import annotations

import dataclasses
import json
import logging
import os
import pathlib

logging.basicConfig(level=logging.INFO)


@dataclasses.dataclass(frozen=True) #, slots=True) #, slots breaks because its already defined?
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
	"Necromancer": [{"Node": {"name": "Nine Lives", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Int.png", "isNotable": True, "skill" : 27602}, 
		"offset": Point2D(-1500, -1000)}],
	"Guardian": [{"Node": {"name": "Searing Purity", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/StrInt.png", "isNotable": True, "skill" : 57568}, 
		"offset": Point2D(-1000, 1500)}],
	"Berserker": [{"Node": {"name": "Indomitable Resolve", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Str.png", "isNotable": True, "skill" : 52435}, 
		"offset": Point2D(-1000, 0)}],
	"Ascendant": [{"Node": {"name": "Unleashed Potential", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/SkillPoint.png", "skill" : 19355}, 
		"offset": Point2D(-1000, 1000)}],
	"Champion": [{"Node": {"name": "Fatal Flourish", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/StrDex.png", "isNotable": True, "skill" : 42469}, 
		"offset": Point2D(0, 1000)}],
	"Raider": [{"Node": {"name": "Fury of Nature", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/Dex.png", "isNotable": True, "skill" : 18054}, 
		"offset": Point2D(1000, -1500)}],
	"Saboteur": [{"Node": {"name": "Harness the Void", "icon": "Art/2DArt/SkillIcons/passives/Ascendants/DexInt.png", "isNotable": True, "skill" : 57331}, 
		"offset": Point2D(1000, -1500)}],
}
EXTRA_NODE_IDS = { # these can be any value but for now they are hardcoded to what random numbers were generated last time for consistency, the "hash" value is what we should probs use though as it's the value in the ggpk
	"Nine Lives": {"NodeID": 33600, "GroupID" : 44472},
	"Searing Purity": {"NodeID": 22278, "GroupID" : 50933},
	"Soul Drinker": {"NodeID": 19264, "GroupID" : 37841, "hash" : 45999},
	"Harness the Void": {"GroupID" : 37841},
	"Fury of Nature": {"NodeID": 62630, "GroupID" : 56600},
	"Fatal Flourish": {"NodeID": 11264, "GroupID" : 63033},
	"Indomitable Resolve": {"NodeID": 15386, "GroupID" : 25519},
	"Unleashed Potential": {"NodeID": 55193, "GroupID" : 60495},
}
EXTRA_NODES_STATS = { # these should not be hardcoded here, but should be inserted later via the exporter from the ggpk (they are AscendencySpecialEldritch in PassiveSkills.dat, though reminder text seems to be missing)
	"Nine Lives": {"stats": ["25% of Damage taken Recouped as Life, Mana and Energy Shield", "Recoup Effects instead occur over 3 seconds"], "reminderText": ["(Only Damage from Hits can be Recouped, over 4 seconds following the Hit)"]}, 
	"Searing Purity": {"stats": ["45% of Chaos Damage taken as Fire Damage", "45% of Chaos Damage taken as Lightning Damage"], "reminderText": []},
	"Soul Drinker": {"stats": ["2% of Damage Leeched as Energy Shield", "20% increased Attack and Cast Speed while Leeching Energy Shield", "Energy Shield Leech effects are not removed when Energy Shield is Filled"], "reminderText": ["(Leeched Energy Shield is recovered over time. Multiple Leeches can occur simultaneously, up to a maximum rate)"]},
	"Harness the Void": {"stats": ["27% chance to gain 25% of Non-Chaos Damage with Hits as Extra Chaos Damage", "13% chance to gain 50% of Non-Chaos Damage with Hits as Extra Chaos Damage", "7% chance to gain 100% of Non-Chaos Damage with Hits as Extra Chaos Damage"], "reminderText": []},
	"Fury of Nature" : {"stats": ["Non-Damaging Elemental Ailments you inflict spread to nearby enemies in a radius of 20", "Non-Damaging Elemental Ailments you inflict have 100% more Effect"], "reminderText": ["(Elemental Ailments are Ignited, Scorched, Chilled, Frozen, Brittled, Shocked, and Sapped)"]},
	"Fatal Flourish": {"stats": ["Final Repeat of Attack Skills deals 60% more Damage", "Non-Travel Attack Skills Repeat an additional Time"], "reminderText": []},
	"Indomitable Resolve": {"stats": ["Deal 10% less Damage", "Take 25% less Damage"], "reminderText": []},
	"Unleashed Potential" : {"stats": ["400% increased Endurance, Frenzy and Power Charge Duration", "25% chance to gain a Power, Frenzy or Endurance Charge on Kill", "+1 to Maximum Endurance Charges", "+1 to Maximum Frenzy Charges", "+1 to Maximum Power Charges"], "reminderText": []},
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
            if str(EXTRA_NODE_IDS[node["Node"]["name"]]["GroupID"]) in data["groups"]: # using hardcoded value from last time, can use another method instead, like just grabbing the next available value
                print("GroupID already taken")
                return
            node["Node"]["group"] = EXTRA_NODE_IDS[node["Node"]["name"]]["GroupID"]
            data["groups"][node["Node"]["group"]] = {"x": NODE_GROUPS[ascendancy].x + node["offset"].x, "y": NODE_GROUPS[ascendancy].y + node["offset"].y, "orbits": [0], "nodes": [node["Node"]["skill"]]}
            data["nodes"][node["Node"]["skill"]] = node["Node"] | {"ascendancyName": ascendancy, "orbit": 0, "orbitIndex": 0, "out": [], "in": [], "stats": [], "reminderText": []}
            if node["Node"]["name"] in EXTRA_NODES_STATS:
                data["nodes"][node["Node"]["skill"]]["stats"] = EXTRA_NODES_STATS[node["Node"]["name"]]["stats"]
                data["nodes"][node["Node"]["skill"]]["reminderText"] = EXTRA_NODES_STATS[node["Node"]["name"]]["reminderText"]
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
