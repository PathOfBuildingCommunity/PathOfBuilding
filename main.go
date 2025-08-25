package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
)

func main() {
	// Set the PathOfBuilding root directory (adjust as needed)
	pobRoot := "/home/alexander/dev/investigations/PathOfBuilding" // Change this if you move the repo

	// Build absolute paths
	srcDir := filepath.Join(pobRoot, "src")
	itemsJSON := filepath.Join(pobRoot, "jsons", "items.json")
	passivesJSON := filepath.Join(pobRoot, "jsons", "passives.json")

	// Set LUA_PATH so LuaJIT can find modules in runtime/lua
	runtimeLua := filepath.Join(pobRoot, "runtime", "lua")
	runtime := filepath.Join(pobRoot, "runtime")
	os.Setenv("LUA_PATH", runtimeLua+"/?.lua;"+runtimeLua+"/?/init.lua;;")
	os.Setenv("LUA_CPATH", runtime+"/?.so;"+runtime+"/?.dll;;")

	// Change working directory to src so Launch.lua can be found
	err := os.Chdir(srcDir)
	if err != nil {
		log.Fatalf("error changing to src directory: %v", err)
	}

	// Use absolute paths for JSON files to avoid any path resolution issues
	cmd := exec.Command("luajit", "HeadlessWrapper.lua", itemsJSON, passivesJSON)
	fmt.Printf("Running command: luajit HeadlessWrapper.lua %s %s\n", itemsJSON, passivesJSON)
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println(string(output))
		log.Fatalf("error running headless shit: %v", err)
	}
	fmt.Println(string(output))
}
