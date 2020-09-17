"""Oodle bundle tooling."""
import os
import struct
import dataclasses
import typing
import sys

def unpack(in_file: str, out_file: str):
    os.system(f"ooz -f -p {in_file} {out_file}")

def extract_file(bundle_name: str, offset: int, num_bytes_to_read: int, output_name: str):
    # NOTE: a x64 release compiled ooz library is pulled from here: https://github.com/uilman/ooz/tree/poe-export
    # You might need to make one small change for the code to compile (depending on your compiler)
    # Around Line 4805
    # -    std::vector<std::size_t> sizes =DecompressPoEBundle2(input,&decompressedOutput,decompressedSize);
    # +    std::vector<std::uint32_t> sizes = DecompressPoEBundle2(input,&decompressedOutput,decompressedSize);
    cmd = f"ooz -g {bundle_name} {offset} {num_bytes_to_read} {output_name}"
    #print(cmd)
    os.system(cmd)

@dataclasses.dataclass
class Bundle:
    name_length: int
    name: str
    uncompressed_bundle_size: int

@dataclasses.dataclass
class FileInfoFile:
    fnv_1: int
    fnv_2: int
    bundle_index: int
    file_offset: int
    file_size: int

@dataclasses.dataclass
class PathRep:
    unknown1: int
    unknown2: int
    inner_bundle_offset: int
    bundle_size: int
    inner_bundle_size: int

def unpack_inner(in_file: str, out_file: str) -> typing.Any:
    with open(in_file, "rb") as f:
        record_count = struct.unpack("<I", f.read(4))[0]
        records = []
        for _ in range(record_count):
            name_length = struct.unpack("<I", f.read(4))[0]
            name, uncompressed_bundle_size = struct.unpack(
                f"<{name_length}sI", f.read(name_length + 4)
            )
            records.append(Bundle(name_length, name, uncompressed_bundle_size))
        file_count = struct.unpack("<I", f.read(4))[0]
        file_info = [
            FileInfoFile(*t) for t in struct.iter_unpack("<5I", f.read(file_count * 20))
        ]
        path_rep_count = struct.unpack("<I", f.read(4))[0]
        path_rep_structs = [
            PathRep(*t) for t in struct.iter_unpack("<5I", f.read(path_rep_count * 20))
        ]
        with open(out_file, "wb") as o:
            o.write(f.read())
    return records, file_info, path_rep_structs

def findBundle(name, file_list, bundle_list, extract=True):
    # modify string to PoE standard
    org_name = name
    name = name.lower() + "++"

    result = FNV1a(name)

    for i in range(len(file_list)):
        fnv = file_list[i].fnv_1 + (file_list[i].fnv_2 << 32)
        if fnv == result:
            #print(f"Found '{org_name}' in '{file_list[i]}' which is in bundle '{bundle_list[file_list[i].bundle_index].name.decode("utf-8") + '.bundle.bin'}'")
            if extract:
                extract_file(bundle_list[file_list[i].bundle_index].name.decode("utf-8") + '.bundle.bin', 
                             file_list[i].file_offset, file_list[i].file_size, org_name)
            return bundle_list[file_list[i].bundle_index].name.decode("utf-8") + '.bundle.bin'

def main(flist, test=False):
    unpack("_.index.bin", "_.index.bin.decoded")
    bundle_list, file_list, path_list = unpack_inner("_.index.bin.decoded", "inner.bundle.bin")
    print(len(bundle_list), len(file_list), len(path_list))

    #test = True
    if test:
        dat_files, txt_files = Test()
        needed = dict()
        for name in dat_files:
            #print(name)
            n = findBundle(name, file_list, bundle_list, False)
            if n == None:
                print("ERROR: ", name)
            needed[n] = True
        for name in txt_files:
            #print(name)
            n = findBundle(name, file_list, bundle_list, False)
            if n == None:
                print("ERROR: ", name)
            needed[n] = True
        for n in needed.keys():
            print(n)
    else:
        for name in flist:
            print(name)
            findBundle(name, file_list, bundle_list)
    

def FNV1a(name):
    # Set the offset basis
    hash = 0xcbf29ce484222325

    # For each character
    for character in name:

        # Xor with the current character
        hash ^= ord(character)

        # Multiply by prime
        hash *= 0x100000001b3

        # Clamp
        hash &= 0xffffffffffffffff

    # Return the final hash as a number
    return hash

def Test():
    dat_files = [
        "Data/Stats.dat",
		"Data/BaseItemTypes.dat",
		"Data/WeaponTypes.dat",
		"Data/ShieldTypes.dat",
		"Data/ComponentArmour.dat",
		"Data/Flasks.dat",
		"Data/ComponentCharges.dat",
		"Data/ComponentAttributeRequirements.dat",
		"Data/PassiveSkills.dat",
		"Data/PassiveSkillBuffs.dat",
		"Data/PassiveTreeExpansionJewelSizes.dat",
		"Data/PassiveTreeExpansionJewels.dat",
		"Data/PassiveJewelSlots.dat",
		"Data/PassiveTreeExpansionSkills.dat",
		"Data/PassiveTreeExpansionSpecialSkills.dat",
		"Data/Mods.dat",
		"Data/ModType.dat",
		"Data/ModDomains.dat",
		"Data/ModGenerationType.dat",
		"Data/ModFamily.dat",
		"Data/ModAuraFlags.dat",
		"Data/ActiveSkills.dat",
		"Data/ActiveSkillTargetTypes.dat",
		"Data/ActiveSkillType.dat",
		"Data/Ascendancy.dat",
		"Data/ClientStrings.dat",
		"Data/ItemClasses.dat",
		"Data/SkillTotems.dat",
		"Data/SkillTotemVariations.dat",
		"Data/SkillMines.dat",
		"Data/Essences.dat",
		"Data/EssenceType.dat",
		"Data/Characters.dat",
		"Data/BuffDefinitions.dat",
		"Data/BuffCategories.dat",
		"Data/BuffVisuals.dat",
		"Data/HideoutNPCs.dat",
		"Data/NPCs.dat",
		"Data/CraftingBenchOptions.dat",
		"Data/CraftingItemClassCategories.dat",
		"Data/CraftingBenchUnlockCategories.dat",
		"Data/MonsterVarieties.dat",
		"Data/MonsterResistances.dat",
		"Data/MonsterTypes.dat",
		"Data/DefaultMonsterStats.dat",
		"Data/SkillGems.dat",
		"Data/GrantedEffects.dat",
		"Data/GrantedEffectsPerLevel.dat",
		"Data/ItemExperiencePerLevel.dat",
		"Data/EffectivenessCostConstants.dat",
		"Data/StatInterpolationTypes.dat",
		"Data/Tags.dat",
		"Data/GemTags.dat",
		"Data/ItemVisualIdentity.dat",
		"Data/AchievementItems.dat",
		"Data/MultiPartAchievements.dat",
		"Data/PantheonPanelLayout.dat"
    ]
    txt_files = [
        "Metadata/StatDescriptions/passive_skill_aura_stat_descriptions.txt",
		"Metadata/StatDescriptions/passive_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/active_skill_gem_stat_descriptions.txt",
		"Metadata/StatDescriptions/advanced_mod_stat_descriptions.txt",
		"Metadata/StatDescriptions/aura_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/banner_aura_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/beam_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/brand_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/buff_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/curse_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/debuff_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/gem_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_attack_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/minion_spell_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/monster_stat_descriptions.txt",
		"Metadata/StatDescriptions/offering_skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/skillpopup_stat_filters.txt",
		"Metadata/StatDescriptions/skill_stat_descriptions.txt",
		"Metadata/StatDescriptions/stat_descriptions.txt",
		"Metadata/StatDescriptions/variable_duration_skill_stat_descriptions.txt"
    ]
    return dat_files, txt_files

if __name__ == "__main__":
    main(sys.argv[1:])
